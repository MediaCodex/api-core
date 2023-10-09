resource "aws_iam_role_policy" "dynamodb" {
  name   = var.name
  role   = var.role
  policy = data.aws_iam_policy_document.dynamodb.json
}

data "aws_iam_policy_document" "dynamodb" {
  dynamic "statement" {
    for_each = var.tables

    content {
      # "arn::etc/example-table" -> "ExampleTable"
      sid = replace(title(
        replace(element(
          split("/", statement.value["arn"]),
          length(split("/", statement.value["arn"])) - 1
        ), "-", " ")
      ), " ", "", )

      actions = flatten([
        # read
        statement.value["enable_read"] == false ? [] : [
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:BatchGetItem"
        ],

        # write
        statement.value["enable_write"] == false ? [] : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateTimeToLive"
        ],

        # delete
        statement.value["enable_delete"] == false ? [] : [
          "dynamodb:DeleteItem"
        ],

        # stream
        statement.value["enable_stream"] == false ? [] : [
          "dynamodb:ListStreams",
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator"
        ]
      ])

      resources = compact([
        statement.value["arn"],
        statement.value["enable_read"] ? "${statement.value["arn"]}/index/*" : "",
        statement.value["enable_stream"] ? "${statement.value["arn"]}/stream/*" : ""
      ])
    }
  }
}
