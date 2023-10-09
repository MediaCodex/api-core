import { AttributeType } from '@aws-sdk/client-cognito-identity-provider'
import middy, { MiddyfiedHandler } from '@middy/core'
import httpErrorHandler from '@middy/http-error-handler'
import jsonBodyParser from '@middy/http-json-body-parser'
import inputOutputLogger from '@middy/input-output-logger'
import { Handler } from 'aws-lambda'

export const cognitoTriggerWrapper = (handler: Handler): MiddyfiedHandler => {
  return middy(handler)
    .use(inputOutputLogger())
    .use(httpErrorHandler())
    .use(jsonBodyParser())
}

export const getUserAttribute = (
  attributes: AttributeType[] | undefined,
  name: string
): string | undefined => {
  return attributes?.find((attr) => attr.Name === name)?.Value
}
