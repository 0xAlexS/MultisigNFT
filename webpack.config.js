const path = require('path');

module.exports = {
  entry: './src/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  },
  devServer: {
    hot: true
  },
  devtool: 'source-map',
  mode: process.env.NODE_ENV === 'production' ? 'production' : 'development'
};