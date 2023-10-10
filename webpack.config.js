const path = require('path')
const { IgnorePlugin } = require('webpack')

/**
 * Lambda Functions
 */
const entryPoints = {
  // 'cognito-pre-token-gen': './src/controllers/cognito/preTokenGen.ts',
  'cognito-post-authentication': './src/controllers/cognito/postAuthentication.ts',
  'sqs-sync-user': './src/controllers/sqs/syncUser.ts',
}

/**
 * Webpack config
 */
module.exports = {
  mode: 'production',
  target: 'node18',
  entry: entryPoints,
  // devtool: 'source-map',

  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ]
  },

  resolve: {
    extensions: ['.tsx', '.ts', '.js']
  },

  output: {
    path: path.join(__dirname, 'dist'),
    library: {
      type: 'commonjs-module'
    }
  },

  optimization: {
    minimize: true
  },

  plugins: [
    // https://github.com/aws/aws-sdk-js-v3/issues/5301
    new IgnorePlugin({ resourceRegExp: /^aws-crt$/ })
  ]
}
