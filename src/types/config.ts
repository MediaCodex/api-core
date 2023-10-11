export type TablesConfig = {
  [key: string]: {
    name: string
  } & Record<`${string}Index`, string>
}

export type Config = {
  tables: TablesConfig

  // aws
  awsRegion: string

  // cdn
  cdnDomain?: string
  cdnR2Bucket?: string
  cdnSecretName: string
  cdnBucketMap: {
    [dir: string]: string
  }
  
  // auth
  userSyncQueueUrl?: string
  userPoolId?: string
  avatarsBucket?: string

  // misc
  gravatarSize: string
}