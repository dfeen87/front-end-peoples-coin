# Stage 1: Build the application using a Node.js environment
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Create the final, lean production image
FROM node:20-alpine
WORKDIR /app

# Copy the built application from the 'builder' stage
COPY --from=builder /app/dist ./dist

# It's good practice to copy over package.json in case the server needs it
COPY package.json ./

# The port your application will run on
EXPOSE 8080

# The command that will run your application server
CMD ["node", "dist/server/index.js"]
