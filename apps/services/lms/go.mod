module github.com/universidad/platform/apps/services/lms

go 1.22

require (
	github.com/google/uuid v1.6.0
	github.com/universidad/platform/packages/api-contracts v0.0.0
	github.com/universidad/platform/packages/error-handling v0.0.0
	github.com/universidad/platform/packages/nosql v0.0.0
	github.com/universidad/platform/packages/observability v0.0.0
)

replace (
	github.com/universidad/platform/packages/api-contracts => ../../../packages/api-contracts
	github.com/universidad/platform/packages/error-handling => ../../../packages/error-handling
	github.com/universidad/platform/packages/nosql => ../../../packages/nosql
	github.com/universidad/platform/packages/observability => ../../../packages/observability
)
