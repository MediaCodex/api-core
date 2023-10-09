export * from './entities'

export enum AvatarSource {
  None = 'none',
  Internal = 'internal',
  Gravatar = 'gravatar'
}

export type SyncUserMessage = {
  userId: string
}