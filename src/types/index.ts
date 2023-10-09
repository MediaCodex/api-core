export * from './entities'

export enum AvatarSource {
  None = 'none',
  Internal = 'internal',
  Gravatar = 'gravatar'
}

// NOTE: the gateway SQS Integration doesn't like mapping context keys into JSON strings
// export type SyncUserMessage = {
//   userId: string
// }
export type SyncUserMessage = string