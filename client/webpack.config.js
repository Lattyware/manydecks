const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const sass = require("sass");

module.exports = (env, argv) => {
  // WebStorm doesn't give any arguments, causing this to blow up without the check.
  const mode = typeof argv === "undefined" ? "production" : argv.mode;

  const prod = mode === "production";
  const dev = mode === "development";

  const dist = path.resolve(__dirname, "dist");
  const src = path.resolve(__dirname, "src");

  const plugins = [
    new HtmlWebpackPlugin({
      template: "src/html/index.html",
      filename: "index.html",
      inject: "body",
      test: /\.html$/,
    }),
  ];

  const cssLoaders = [
    // Extract to separate file.
    {
      loader: "file-loader",
      options: {
        name: prod ? "[name].[contenthash].css" : "[name].css",
        outputPath: "assets/styles",
        esModule: false,
      },
    },
    {
      loader: "extract-loader",
    },
    // Load CSS to inline styles.
    {
      loader: "css-loader",
      options: { sourceMap: dev },
    },
    // Transform CSS for compatibility.
    {
      loader: "postcss-loader",
      options: {
        sourceMap: dev,
      },
    },
    // Allow relative URLs.
    {
      loader: "resolve-url-loader",
      options: { sourceMap: dev },
    },
    // Load SASS to CSS.
    {
      loader: "sass-loader",
      options: {
        implementation: sass,
        sourceMap: true,
        sassOptions: {
          includePaths: ["node_modules"],
        },
      },
    },
  ];

  const elmLoaders = [
    // Load elm to JS.
    {
      loader: "elm-webpack-loader",
      options: {
        files: [path.resolve(src, "elm/ManyDecks.elm")],
        optimize: prod,
        debug: dev,
        forceWatch: dev,
        cwd: __dirname,
      },
    },
  ];

  return {
    context: path.resolve(__dirname),
    entry: {
      index: "./src/ts/index.ts",
    },
    devtool: prod ? undefined : "eval-source-map",
    output: {
      path: dist,
      publicPath: "/",
      filename: prod ? "[name].[contenthash].js" : "[name].js",
    },
    module: {
      rules: [
        // HTML
        {
          test: /\.html$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: [
            {
              loader: "html-loader",
              options: {
                attributes: {
                  list: [
                    {
                      tag: "img",
                      attribute: "src",
                      type: "src",
                    },
                    {
                      tag: "link",
                      attribute: "href",
                      type: "src",
                    },
                  ],
                },
              },
            },
          ],
        },
        // Elm.
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: elmLoaders,
        },
        // Typescript scripts.
        {
          test: /\.ts$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: "ts-loader",
          include: src,
        },
        // Styles.
        {
          test: /\.s?css$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: cssLoaders,
        },
        // Image assets.
        {
          test: /\.(jpg|png|svg)$/,
          loader: "file-loader",
          options: {
            name: prod
              ? "assets/images/[name].[contenthash].[ext]"
              : "assets/images/[name].[ext]",
            esModule: false,
          },
        },
      ],
    },
    resolve: {
      extensions: [".js", ".ts", ".elm", ".scss"],
      modules: ["node_modules"],
    },
    plugins,
    devServer: {
      hot: true,
      allowedHosts: ["localhost"],
      proxy: {
        // Forward to the server.
        "/api/**": {
          target: "http://localhost:8083",
          ws: true,
        },
        // As we are an SPA, this lets us route all requests to the index.
        "**": {
          target: "http://localhost:8082",
          pathRewrite: {
            ".*": "",
          },
        },
      },
    },
  };
};
