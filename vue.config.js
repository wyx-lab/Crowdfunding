const { defineConfig } = require('@vue/cli-service')
const webpack = require('webpack');
const path = require('path');
module.exports = defineConfig({
  transpileDependencies: true,
  configureWebpack: {
    plugins: [
      new webpack.ProvidePlugin({
        process: 'process/browser',
      }),
      new webpack.ProvidePlugin({
        Buffer: ['buffer', 'Buffer'],
      }),
    ],
    resolve: {
      fallback: {
        "process": require.resolve("process/browser"),
        "stream": require.resolve("stream-browserify"),
        "buffer": require.resolve("buffer/"),
        "crypto": require.resolve("crypto-browserify"),
        "http": require.resolve("stream-http"),
        "https": require.resolve("https-browserify"),
        "os": require.resolve("os-browserify/browser"),
        "url": require.resolve("url-browserify"),
        "assert": require.resolve("assert/"),
        path: require.resolve('path-browserify')
      }
    }
  }
})
