module github.com/universidad/platform/apps/services/person

go 1.22

require (
	github.com/redis/go-redis/v9 v9.7.1
	github.com/universidad/platform/packages/api-contracts v0.0.0
	github.com/universidad/platform/packages/error-handling v0.0.0
	github.com/universidad/platform/packages/mysql v0.0.0
	github.com/universidad/platform/packages/observability v0.0.0
)

require (
	filippo.io/edwards25519 v1.1.0 // indirect
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/go-sql-driver/mysql v1.8.1 // indirect
)

replace (
	github.com/universidad/platform/packages/api-contracts => ../../../packages/api-contracts
	github.com/universidad/platform/packages/error-handling => ../../../packages/error-handling
	github.com/universidad/platform/packages/messaging => ../../../packages/messaging
	github.com/universidad/platform/packages/mysql => ../../../packages/mysql
	github.com/universidad/platform/packages/observability => ../../../packages/observability
)
