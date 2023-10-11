export * from './cognito'
import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm"
import config from "../config"
import { GetSecretValueCommand, SecretsManagerClient } from '@aws-sdk/client-secrets-manager'

export const getSSMParam = async (key: string) => {
  const ssmClient = new SSMClient({ region: config.awsRegion })
  const res = await ssmClient.send(new GetParameterCommand({
    Name: key,
    WithDecryption: true
  }))
  return res.Parameter?.Value
}

export const getSecretsManagerSecret = async (name: string) => {
  const secretsManager = new SecretsManagerClient({ region: config.awsRegion })
  const secret = await secretsManager.send(new GetSecretValueCommand({
    SecretId: name
  }))
  return secret.SecretString
}