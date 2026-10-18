module github.com/universidad/platform/apps/services/academic

go 1.22

require (
	github.com/universidad/platform/packages/api-contracts v0.0.0
	github.com/universidad/platform/packages/error-handling v0.0.0
	github.com/universidad/platform/packages/mysql v0.0.0
	github.com/universidad/platform/packages/observability v0.0.0
)

require (
	filippo.io/edwards25519 v1.1.0 // indirect
	github.com/go-sql-driver/mysql v1.8.1 // indirect
)

replace (
	github.com/universidad/platform/packages/api-contracts => ../../../packages/api-contracts
	github.com/universidad/platform/packages/error-handling => ../../../packages/error-handling
	github.com/universidad/platform/packages/messaging => ../../../packages/messaging
	github.com/universidad/platform/packages/mysql => ../../../packages/mysql
	github.com/universidad/platform/packages/observability => ../../../packages/observability
)
