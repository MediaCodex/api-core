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
  cdnR2Bucket?: string
  cdnDomain?: string
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