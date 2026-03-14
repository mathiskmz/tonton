# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Setup
bundle install
rails db:create db:migrate

# Development server
rails server

# Tests
rails test                              # All tests
rails test test/models/user_test.rb    # Single file

# Code quality
rubocop                                 # Linting
brakeman                                # Security scan
bundle audit                            # Gem vulnerabilities
```

## Architecture

**Tonton** is a Rails 8.1.2 chat app where users converse with an LLM configured as "an educated uncle at a family dinner" (French persona).

**Models:**
- `User` (Devise) → `has_many :chats`
- `Chat` (title, user_id) → `has_many :messages`
- `Message` (content, role: user/assistant, chat_id)

**Key flow — message creation** (`MessagesController#create`):
1. Save user message with `role: "user"`
2. Call RubyLLM (`ruby_llm` gem) with a French system prompt
3. Save the LLM response as a message with `role: "assistant"`

**Authentication:** All routes require login via `before_action :authenticate_user!` in `ApplicationController`, except `PagesController` (home page).

**Routes:**
```
GET  /              → pages#home (public)
GET  /chats         → chats#index
GET  /chats/new     → chats#new
POST /chats         → chats#create
GET  /chats/:id     → chats#show
POST /chats/:id/messages → messages#create
```

**Frontend:** Bootstrap 5.3 + Hotwire (Turbo + Stimulus) + import maps. No Node.js build step.

**Environment variables** (`.env` in dev):
- `GITHUB_TOKEN_OPENAI` — LLM API token used by RubyLLM

## Style

- Line length: 120 characters max (`.rubocop.yml`)
- Rubocop excludes: `bin/`, `db/`, `config/`, `test/`
- Ruby 3.3.5 (`.ruby-version`)
