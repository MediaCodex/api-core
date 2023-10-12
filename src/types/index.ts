export * from './entities'
export * from './config'

// NOTE: the gateway SQS Integration doesn't like mapping context keys into JSON strings
// export type SyncUserMessage = {
//   userId: string
// }
export type SyncUserMessage = string

export type CloudflareR2Secret = {
  accountId: string
  r2AccessToken: string
  r2AccessKeyId: string
  r2SecretAccessKey: string
}