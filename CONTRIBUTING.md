# Contributing

This is an open project, and we welcome contributions of all kinds from anyone who wishes to contribute.

If you are a new contributor, we know it can be intimidating, but please don't hesitate to ask for help to get started 
or if you face issues while making a change.

## Community

The project aims to be open and welcoming to all. Please keep that in mind in your interactions with others. If you 
face any issues, please let us know, and we will do out best to solve any problems.

Please also be aware: everyone involved in the project is contributing their time as volunteers. Please don't demand 
things or time of others, and be patient where people can't find time. 

## Making changes

### Getting started

 - [Make a fork of the project.][github-forking] 
 - Set up an editor that will work for Elm and TypeScript. [Atom][atom] and [Visual Studio Code][vs-code] are good free 
   options with support for both languages through plugins. We also highly recommend installing [a prettier plugin].
 - You will need a running Postgres database. You can install it normally, but if you have Docker set up, the easiest 
   way is just to create a container, i.e: 
   `docker run -p 5432:5432 -e POSTGRES_USER=massivedecks -e POSTGRES_PASSWORD=massivedecks -d postgres:13`. 
 - You can run the application locally in watch mode using `npm run dev`, this will make it restart automatically when 
   you make changes. You need to do this in the client and the server, and should then be able to access the application 
   at `http://localhost:8082`.
 
[github-forking]: https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/fork-a-repo
[atom]: https://atom.io/
[vs-code]: https://code.visualstudio.com/
[prettier-plugin]: https://prettier.io/docs/en/editors.html

### Advice for making good pull requests

 - Comment on an existing issue or make a new one for what you plan on doing, so others know you are working on it.
 - Please make sure you run the current version of prettier installed in the project on any files you change to 
   ensure they have the project code style. The easiest way to do this is to set it up with your editor to run 
   automatically, see above.
 - Don't be afraid to create work-in-progress pull requests to get feedback from others if you are not sure on the best 
   way to solve a problem or get stuck.
 - If you are installing additional dependencies, please try to keep them minimal (e.g: don't install giant frameworks 
   for one or two small features) and check they don't have vulnerabilities and are trustworthy projects.

