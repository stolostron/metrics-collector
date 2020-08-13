package utils

import (
	"context"
	"reflect"
	"testing"
)

func TestWithClusterID(t *testing.T) {
	ctx := context.Background()
	ctx = context.WithValue(ctx, ClusterIDCtx, "a-b-c-d")

	want := ctx
	actual := WithClusterID(context.Background(), "a-b-c-d")
	if !reflect.DeepEqual(want, actual) {
		t.Fatalf("failed to set context")
	}
}

func TestClusterIDFromContext(t *testing.T) {
	ctx := context.Background()
	ctx = context.WithValue(ctx, ClusterIDCtx, "a-b-c-d")
	want := "a-b-c-d"
	actual, okay := ClusterIDFromContext(ctx)
	if want != actual || !okay {
		t.Fatalf("failed to get context")
	}
}
