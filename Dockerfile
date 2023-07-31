# syntax=docker/dockerfile:1
FROM ruby:3.0

RUN apt update
RUN gem install bundler

WORKDIR /code/

# Copy only Gemfile and Gemfile.lock so that dependencies are cached.
COPY Gemfile Gemfile.lock /code/
RUN bundle install

COPY . /code/

CMD ["bundle", "exec", "jekyll", "build"]
