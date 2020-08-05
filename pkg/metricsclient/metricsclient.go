package metricsclient

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/gogo/protobuf/proto"
	"github.com/golang/snappy"
	"github.com/prometheus/client_golang/prometheus"
	clientmodel "github.com/prometheus/client_model/go"
	"github.com/prometheus/common/expfmt"
	"github.com/prometheus/prometheus/prompb"

	"github.com/openshift/telemeter/pkg/reader"
)

const (
	nameLabelName = "__name__"
)

var (
	gaugeRequestRetrieve = prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "metricsclient_request_retrieve",
		Help: "Tracks the number of metrics retrievals",
	}, []string{"client", "status_code"})
	gaugeRequestSend = prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "metricsclient_request_send",
		Help: "Tracks the number of metrics sends",
	}, []string{"client", "status_code"})
)

func init() {
	prometheus.MustRegister(
		gaugeRequestRetrieve, gaugeRequestSend,
	)
}

type Client struct {
	client      *http.Client
	maxBytes    int64
	timeout     time.Duration
	metricsName string
	logger      log.Logger
}

type PartitionedMetrics struct {
	ClusterID string
	Families  []*clientmodel.MetricFamily
}

func New(logger log.Logger, client *http.Client, maxBytes int64, timeout time.Duration, metricsName string) *Client {
	return &Client{
		client:      client,
		maxBytes:    maxBytes,
		timeout:     timeout,
		metricsName: metricsName,
		logger:      log.With(logger, "component", "metricsclient"),
	}
}

func (c *Client) Retrieve(ctx context.Context, req *http.Request) ([]*clientmodel.MetricFamily, error) {
	if req.Header == nil {
		req.Header = make(http.Header)
	}
	req.Header.Set("Accept", strings.Join([]string{string(expfmt.FmtProtoDelim), string(expfmt.FmtText)}, " , "))

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	req = req.WithContext(ctx)
	defer cancel()

	families := make([]*clientmodel.MetricFamily, 0, 100)
	err := withCancel(ctx, c.client, req, func(resp *http.Response) error {
		switch resp.StatusCode {
		case http.StatusOK:
			gaugeRequestRetrieve.WithLabelValues(c.metricsName, "200").Inc()
		case http.StatusUnauthorized:
			gaugeRequestRetrieve.WithLabelValues(c.metricsName, "401").Inc()
			return fmt.Errorf("Prometheus server requires authentication: %s", resp.Request.URL)
		case http.StatusForbidden:
			gaugeRequestRetrieve.WithLabelValues(c.metricsName, "403").Inc()
			return fmt.Errorf("Prometheus server forbidden: %s", resp.Request.URL)
		case http.StatusBadRequest:
			gaugeRequestRetrieve.WithLabelValues(c.metricsName, "400").Inc()
			return fmt.Errorf("bad request: %s", resp.Request.URL)
		default:
			gaugeRequestRetrieve.WithLabelValues(c.metricsName, strconv.Itoa(resp.StatusCode)).Inc()
			return fmt.Errorf("Prometheus server reported unexpected error code: %d", resp.StatusCode)
		}

		// read the response into memory
		format := expfmt.ResponseFormat(resp.Header)
		r := &reader.LimitedReader{R: resp.Body, N: c.maxBytes}
		decoder := expfmt.NewDecoder(r, format)
		for {
			family := &clientmodel.MetricFamily{}
			families = append(families, family)
			if err := decoder.Decode(family); err != nil {
				if err == io.EOF {
					break
				}
				return err
			}
		}

		return nil
	})
	if err != nil {
		return nil, err
	}
	return families, nil
}

func (c *Client) Send(ctx context.Context, req *http.Request, families []*clientmodel.MetricFamily) error {
	buf := &bytes.Buffer{}
	if err := Write(buf, families); err != nil {
		return err
	}

	if req.Header == nil {
		req.Header = make(http.Header)
	}
	req.Header.Set("Content-Type", string(expfmt.FmtProtoDelim))
	req.Header.Set("Content-Encoding", "snappy")
	req.Body = ioutil.NopCloser(buf)

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	req = req.WithContext(ctx)
	defer cancel()
	level.Debug(c.logger).Log("msg", "start to send")
	return withCancel(ctx, c.client, req, func(resp *http.Response) error {
		defer func() {
			if _, err := io.Copy(ioutil.Discard, resp.Body); err != nil {
				level.Error(c.logger).Log("msg", "error copying body", "err", err)
			}
			resp.Body.Close()
		}()
		level.Debug(c.logger).Log("msg", resp.StatusCode)
		switch resp.StatusCode {
		case http.StatusOK:
			gaugeRequestSend.WithLabelValues(c.metricsName, "200").Inc()
		case http.StatusUnauthorized:
			gaugeRequestSend.WithLabelValues(c.metricsName, "401").Inc()
			return fmt.Errorf("gateway server requires authentication: %s", resp.Request.URL)
		case http.StatusForbidden:
			gaugeRequestSend.WithLabelValues(c.metricsName, "403").Inc()
			return fmt.Errorf("gateway server forbidden: %s", resp.Request.URL)
		case http.StatusBadRequest:
			gaugeRequestSend.WithLabelValues(c.metricsName, "400").Inc()
			level.Debug(c.logger).Log("msg", resp.Body)
			return fmt.Errorf("gateway server bad request: %s", resp.Request.URL)
		default:
			gaugeRequestSend.WithLabelValues(c.metricsName, strconv.Itoa(resp.StatusCode)).Inc()
			body, _ := ioutil.ReadAll(resp.Body)
			if len(body) > 1024 {
				body = body[:1024]
			}
			return fmt.Errorf("gateway server reported unexpected error code: %d: %s", resp.StatusCode, string(body))
		}

		return nil
	})
}

func Read(r io.Reader) ([]*clientmodel.MetricFamily, error) {
	decompress := snappy.NewReader(r)
	decoder := expfmt.NewDecoder(decompress, expfmt.FmtProtoDelim)
	families := make([]*clientmodel.MetricFamily, 0, 100)
	for {
		family := &clientmodel.MetricFamily{}
		if err := decoder.Decode(family); err != nil {
			if err == io.EOF {
				break
			}
			return nil, err
		}
		families = append(families, family)
	}
	return families, nil
}

func Write(w io.Writer, families []*clientmodel.MetricFamily) error {
	// output the filtered set
	compress := snappy.NewBufferedWriter(w)
	encoder := expfmt.NewEncoder(compress, expfmt.FmtProtoDelim)
	for _, family := range families {
		if family == nil {
			continue
		}
		if err := encoder.Encode(family); err != nil {
			return err
		}
	}
	if err := compress.Flush(); err != nil {
		return err
	}
	return nil
}

func withCancel(ctx context.Context, client *http.Client, req *http.Request, fn func(*http.Response) error) error {
	resp, err := client.Do(req)
	defer func() {
		if resp != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		return err
	}

	done := make(chan struct{})
	go func() {
		err = fn(resp)
		close(done)
	}()

	select {
	case <-ctx.Done():
		closeErr := resp.Body.Close()

		// wait for the goroutine to finish.
		<-done

		// err is propagated from the goroutine above
		// if it is nil, we bubble up the close err, if any.
		if err == nil {
			err = closeErr
		}

		// if there is no close err,
		// we propagate the context context error.
		if err == nil {
			err = ctx.Err()
		}
	case <-done:
		// propagate the err from the spawned goroutine, if any.
	}

	return err
}

func DefaultTransport(logger log.Logger, isTLS bool) *http.Transport {
	// Load client cert
	cert, err := tls.LoadX509KeyPair("/etc/certs/client.pem", "/etc/certs/client.key")
	if err != nil {
		level.Error(logger).Log("msg", "failed to load certs", err)
		return nil
	}
	level.Info(logger).Log("msg", "certs loaded")
	// Load CA cert
	caCert, err := ioutil.ReadFile("/etc/certs/ca.pem")
	if err != nil {
		level.Error(logger).Log("msg", "failed to load ca", err)
		return nil
	}
	level.Info(logger).Log("msg", "ca loaded")
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)
	// Setup HTTPS client
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		RootCAs:      caCertPool,
	}
	tlsConfig.BuildNameToCertificate()

	if isTLS {
		return &http.Transport{
			Dial: (&net.Dialer{
				Timeout:   30 * time.Second,
				KeepAlive: 30 * time.Second,
			}).Dial,
			TLSHandshakeTimeout: 10 * time.Second,
			DisableKeepAlives:   true,
			TLSClientConfig:     tlsConfig,
		}
	} else {
		return &http.Transport{
			Dial: (&net.Dialer{
				Timeout:   30 * time.Second,
				KeepAlive: 30 * time.Second,
			}).Dial,
			TLSHandshakeTimeout: 10 * time.Second,
			DisableKeepAlives:   true,
		}
	}
}
func convertToTimeseries(p *PartitionedMetrics, now time.Time) ([]prompb.TimeSeries, error) {
	var timeseries []prompb.TimeSeries

	for _, f := range p.Families {
		for _, m := range f.Metric {
			var ts prompb.TimeSeries

			labelpairs := []prompb.Label{{
				Name:  nameLabelName,
				Value: *f.Name,
			}}

			for _, l := range m.Label {
				labelpairs = append(labelpairs, prompb.Label{
					Name:  *l.Name,
					Value: *l.Value,
				})
			}

			s := prompb.Sample{
				Timestamp: *m.TimestampMs,
			}

			switch *f.Type {
			case clientmodel.MetricType_COUNTER:
				s.Value = *m.Counter.Value
			case clientmodel.MetricType_GAUGE:
				s.Value = *m.Gauge.Value
			case clientmodel.MetricType_UNTYPED:
				s.Value = *m.Untyped.Value
			default:
				return nil, fmt.Errorf("metric type %s not supported", f.Type.String())
			}

			ts.Labels = append(ts.Labels, labelpairs...)
			ts.Samples = append(ts.Samples, s)

			timeseries = append(timeseries, ts)
		}
	}

	return timeseries, nil
}

type clusterIDCtxType int

const (
	clusterIDCtx clusterIDCtxType = iota
)

func (c *Client) RemoteWrite(ctx context.Context, req *http.Request, families []*clientmodel.MetricFamily) error {
	clusterID := "1234567890" //ctx.Value(clusterIDCtx).(string)
	timeseries, err := convertToTimeseries(&PartitionedMetrics{ClusterID: clusterID, Families: families}, time.Now())
	if err != nil {
		msg := "failed to convert timeseries"
		level.Warn(c.logger).Log("msg", msg, "err", err)
		return fmt.Errorf(msg)
	}

	if len(timeseries) == 0 {
		level.Info(c.logger).Log("msg", "no time series to forward to receive endpoint")
		return nil
	}

	wreq := &prompb.WriteRequest{Timeseries: timeseries}

	data, err := proto.Marshal(wreq)
	if err != nil {
		msg := "failed to marshal proto"
		level.Warn(c.logger).Log("msg", msg, "err", err)
		return fmt.Errorf(msg)
	}

	compressed := snappy.Encode(nil, data)

	req1, err := http.NewRequest(http.MethodPost, "https://test-open-cluster-management-monitoring.apps.marco.dev05.red-chesterfield.com/api/metrics/v1/test/api/v1/receive", bytes.NewBuffer(compressed))
	if err != nil {
		msg := "failed to create forwarding request"
		level.Warn(c.logger).Log("msg", msg, "err", err)
		return fmt.Errorf(msg)
	}
	//req.Header.Add("THANOS-TENANT", tenantID)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	req1 = req1.WithContext(ctx)

	resp, err := c.client.Do(req1)
	if err != nil {
		msg := "failed to forward request"
		level.Warn(c.logger).Log("msg", msg, "err", err)
		return fmt.Errorf(msg)
	}

	if resp.StatusCode/100 != 2 {
		// surfacing upstreams error to our users too
		msg := fmt.Sprintf("response status code is %s", resp.Status)
		level.Warn(c.logger).Log("msg", msg)
		return fmt.Errorf(msg)
	}
	return nil
}
