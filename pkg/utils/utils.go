package utils

import "context"

// Add cluster ID to context
type clusterIDCtxType int

const (
	ClusterIDCtx clusterIDCtxType = iota
)

// WithClusterID puts the clusterID into the given context.
func WithClusterID(ctx context.Context, clusterID string) context.Context {
	return context.WithValue(ctx, ClusterIDCtx, clusterID)
}

// ClusterIDFromContext returns the clusterID from the context.
func ClusterIDFromContext(ctx context.Context) (string, bool) {
	p, ok := ctx.Value(ClusterIDCtx).(string)
	return p, ok
}
