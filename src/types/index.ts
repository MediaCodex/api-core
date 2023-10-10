export * from './entities'

// NOTE: the gateway SQS Integration doesn't like mapping context keys into JSON strings
// export type SyncUserMessage = {
//   userId: string
// }
export type SyncUserMessage = string