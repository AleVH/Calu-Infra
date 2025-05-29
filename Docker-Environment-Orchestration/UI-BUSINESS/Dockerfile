# React Native Web - Business
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy the UI source (may be empty at first)
COPY . .

# Scaffold framework if missing
RUN if [ ! -f package.json ]; then \
    npm init -y && \
    npm install react react-dom react-native-web @babel/core @babel/preset-env @babel/preset-react webpack webpack-cli webpack-dev-server babel-loader html-webpack-plugin ; \
fi

# Scaffold app if empty
RUN if [ ! -f index.js ]; then \
    echo "import React from 'react';\n\
    import { AppRegistry } from 'react-native';\n\
    import App from './App';\n\
    AppRegistry.registerComponent('App', () => App);\n\
    AppRegistry.runApplication('App', {\n\
    rootTag: document.getElementById('root'),\n\
    });" > index.js && \
        mkdir -p public && \
        echo "<!DOCTYPE html><html><body><div id='root'></div></body></html>" > public/index.html && \
        echo "import React from 'react';\n\
    import { Text } from 'react-native';\n\
    export default function App() {\n\
    return <Text>Hello from Business UI</Text>;\n\
    }" > App.js && \
        echo "{\n\
    \"presets\": [\"@babel/preset-env\", \"@babel/preset-react\"]\n\
    }" > .babelrc && \
        echo "const path = require('path');\n\
    const HtmlWebpackPlugin = require('html-webpack-plugin');\n\
    module.exports = {\n\
    entry: './index.js',\n\
    module: {\n\
        rules: [ { test: /\\.(js|jsx)$/, exclude: /node_modules/, use: 'babel-loader' } ]\n\
    },\n\
    resolve: {\n\
        extensions: ['.js', '.jsx'],\n\
        alias: { 'react-native$': 'react-native-web' }\n\
    },\n\
    plugins: [ new HtmlWebpackPlugin({ template: './public/index.html' }) ],\n\
    devServer: { port: 3002, open: false },\n\
    };" > webpack.config.js ; \
fi

# Install dependencies (again, safely for either scaffolded or existing projects)
RUN npm install

# Expose web server port
EXPOSE 3000
CMD [ "npx", "webpack-dev-server" ]