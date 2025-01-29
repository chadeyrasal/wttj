# Wttj

## Requirements

- Elixir 1.17.2-otp-26
- Erlang 26.2.5
- Postgresql
- Nodejs 20.11.0
- Yarn 1.22.22

The above can be installed using [asdf](https://asdf-vm.com/) by running `asdf install` in the root of the project. The versions are specified in the `.tool-versions` file.

## How to run the application locally

Running the server:

- Run `mix setup` to install and setup dependencies (this is mandatory as new dependencies have been added to the project)
- Run database migrations `mix ecto.migrate`
- Get seed data to your local development database `mix run priv/repo/seeds.exs`
- Run the server inside an iex session `iex -S mix phx.server`
- You can navigate to `localhost:4000` and have a play with the various endpoints found in `lib/wttj_web/router.ex`

Running the frontend:

- cd into the assets directory `cd assets`
- Run `yarn` to install dependencies (this is mandatory as new dependencies have been added to the project)
- Run the application `yarn dev`
- Navigate to `localhost:4000` in your browser

### How to run automated tests

- backend: `mix test`
- frontend: `cd assets & yarn test`

## How I approched the problem

For each point below, you will find a description of the problem I tried to solve, which decisions I made, why I made those decisions and what I would improve with more time. For each part of the problem, I created a branch and a pull request including a description of the changes and the steps required to manually test the changes. Links to the relevant pull requests are found at the bottom of each section.

### Basic functionality

In the context of a kanban board allowing to follow the progress of candidates applying to a job, the basic functionality consists in being able to drag and drop cards (representing candidates), within a column (representing a stage of the recruitment process) or in a different column (representing a different stage of the recruitment process).

I started by installing all dependencies to be able to run the application and assess what was already there. In the interest of time, I downgraded the OTP version from 27 to 26 so it played better with my existing elixir and erlang setup. When running the application locally, I noticed some alerts in the terminal and in the console and fixed those before starting to add to the codebase.

A drag and drop functionality is a common feature, so I started by researching existing libraries to help me implement it. As implementing this was just one part of the challenge, it seemed reasonable to not reinvent the wheel and use a well maintained library. I first looked into react-beautiful-dnd but found out that it was deprecated. While searching for an alternative I found [Hello pangea DND](https://github.com/hello-pangea/dnd) which is maintained and well documented. The library is supporting a number of drag and drop related features and seemed like a good candidate for long term use and feature expansion of the current application.

How to implement the drag and drop functionality in the frontend:

- Install the library `yarn add @hello-pangea/dnd`
- Wrap the kanban component in the DragDropContext component
- Wrap each column in a Droppable component, which acceprs a `droppableId` prop
- Wrap each candidate card in a Draggable component
- Add the onDragEnd handler to the DragDropContext component
- Implement the onDragEnd logic using the passed result prop, which contains the `draggableId`, the `source` and the `destination` properties. These properties are sufficient for the backend to be able to handle the card move.
- Call the relevant function to update the candidate position in the backend

How I implemented the backend logic:

- At that stage, I built a standard REST endpoint to handle the card move (see router).
- I createe a new function in the existing CandidateController.
- I created a new `reorder_candidates/1` function in the Candidates context to handle the logic.
- I used automated tests to help me ensure all requirements were met:
  - A card can be moved within one column
  - A card can be moved between columns
  - All relevant candidate records are updated to reflect the new card position
  - There are no gaps in the candidates positions and the unique index on the position column is maintained

After this work, the main improvement I would make is to the frontend. The card being moved needs to be dropped in a very specific position within the destination column, and the UI does not not help in knowing whether the card can be dropped. When the card is not dropped quite within the right droppable zone, it is returned to its original position. Looking at the drag and drop library documentation, it appears there are solutions to this issue.

Pull requests:

- [Updating tool versions and fixing all alerts](https://github.com/chadeyrasal/wttj/pull/1)
- [Implementing drag and drop functionality](https://github.com/chadeyrasal/wttj/pull/2)

### Real time collaboration

To make real time collaboration work, several things could be done, but the most important one to me is being able to handle conflicts, ie when two users try to move the same card at the same time. In a real life situation you could imagine that candidate cards could have their content updated from the UI by various people, and this conflict would also need to be handled.

To adopt the right approach for conflict handling, I found mentions of two main approaches: server-sent events (SSE) and Phoenix Channels, which leverage websockets. In the context of a kanban board where information needs to travel from client to server and from server to client as updates are made by the current user and other users, I decided to use Phoenix Channels. They allow for bi-directional communication, and come with the Phoenix framwork.

From my research it seemed a good option to implement some basic authentication before setting up my Phoenix channel. I implemented a very basic log in and log out feature, where a token is generated on log in and remove from the client on log out. I decided to make use of this token to protect the application, and only allow logged in users to access the board. It is a very basic implementation which is lacking some features, especially around session management. It can however, very easily be extended and extra security feeatures can be added, like checking the client token against the database to ensure its validity and the validity of the card move operation.

To be able to use the Phoenix channel, I:

- Created a BoardSocket module to handle the socket connection
- Created a BoardChannel which handles candidate card moves
- Re-used the logic already implemented for reordering cards
- Added new hooks in the frontend to handle card moves by pushing to the channel
- Added a version field to the candidate schema to detect and handle conflicts

Another feature that's important to real time collaboration, is being able to see the changes made by other users. I could think of three main ways to do this:

- Use SSE to send events to the client: could work for the updates, but as I understand there is a fair bit of setup required to make it work.
- Use polling to fetch updates from the server: this would work, but is not super efficient, as the client needs to poll the server at regular intervals, even when nothing has changed since the client has no way to know when updates have happened.
- Use websockets to send events to the client: you get it for free with Phoenix Channels when you've implemented conflict handling as described above.

What could be improved:

- The frontend uses a simple window.alert mechanism to notify the user that another user has moved a card and that's not ideal as it requires the user to click on the alert to close it. A toast notification is better practice in my experience as it informs the user without requiring an action.
- The `reorder` endpoint implemented previously is no longer required, as the channel handles the real time updates. This should be cleaned up.

For this feature as well as the previous one, I have included some logging in specific places, which in a real life scenario would be useful for monitoring and debugging.

Pull requests:

- [Implementing minimal authentication](https://github.com/chadeyrasal/wttj/pull/3)
- [Adding conflict resolution and real time updated](https://github.com/chadeyrasal/wttj/pull/4)
- [Fixing alerting when conflicts occur](https://github.com/chadeyrasal/wttj/pull/5)

### Performance optimization

There are many ways to improve the performance of an application, but just like everything else when building software, it's all about trade-offs.

The obvious optimization and probably the first one that comes to mind, is to look at the database and consider an indexing strategy. Initially I thought about create an index on the candidates table to optimize for fetching candidate records by `job_id` and `id`. In my experience an index that would help with fetching data is worth it when there are more get operations than write operations. Here, everytime a candidate card is moved, we do fetch the relevant candidate record. But updating one index potentially triggers updates for every single candidate record with the source status and with the destination status. If you think about a job, ultimately most candidates will have the `rejected` status. So moving a card at the top of the column would trigger updates for every single candidate record with that status. If the card was at the top of the source column, then every single candidate record with that status would be updated. The TLDR is: there are more write then read operations, so an index would negatively affect the performance.

Another optimization would be to improve the performance of the big write operations that can happen on a card move like described above. Ecto and the Stream module allow us to batch updates. That's a useful thing to do as it lowers the load on the database. Using Stream over Enum also means that the enumerable is traversed once and each element has all the changes applied in one go instead of being processed one by one and traversing the enumerable once for each operation.

In the current implementation, after each card move, whether the move is successful or not, all candidates are broadcasted to all connected clients. This is not ideal, since at most only two statuses are affected by any given move. For example, moving a card from `interview` to `hired` will impact the records with those statuses, so there is no need to all `new` and `rejected` candidates. This is an example of where caching could help. By storing the candidates in a cache, we could reduce the number of updates sent to the client, and by storing the candidates as per their status, we could reasily invalidate the candidate records with a specific status when a card is moved.

There are also several optimizations that could be done on the frontend. The first one I would implement is limiting the amount of candidates displayed in each column on the board. This means we would only load and display a subset of candidates and require a user to scroll and maybe click, to fetch the next batch of candidates. This would reduce loading time and improve the user experience when there are large numbers of candidates for a specific job.

Finally a note, implementing phoenix channels to handle conflicts is in itself an performance optimisation compared to make API calls for each card move. The network load is reduced and latency is potentially reduced as well because there is only one connection per user, since the socket is maintained for the duration of the session.

### Other improvements

- A CI pipeline would be a useful addition to ensure that each pull requests matches basic requirements, like tests passing and the application running.
- In production a handful of e2e tests would be useful to ensure critical paths are working as expected. In our case ensuring that candidate cards are visible to logged in users and that cards can be moved within a column and between column. For this specific projects, I included manual testing instructions in each relevant pull request to ensure that the new features worked as expected and that there was no regression for critical paths.
