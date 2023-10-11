import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm"
import config from "../config"

export const getSSMParam = async (key: string) => {
  const ssmClient = new SSMClient({ region: config.awsRegion })
  const res = await ssmClient.send(new GetParameterCommand({
    Name: key,
    WithDecryption: true
  }))
  return res.Parameter?.Value
}