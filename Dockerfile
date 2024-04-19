FROM ruby:3.2.2
RUN apt-get update && apt-get install -y nodejs && apt install -y libvips-tools
WORKDIR /app
COPY Gemfile* .
RUN bundle install
COPY . .