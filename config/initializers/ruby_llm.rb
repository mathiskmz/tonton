RubyLLM.configure do |config|
  config.openai_api_key = ENV["GITHUB_TOKEN_OPENAI"]
  config.openai_api_base = "https://models.inference.ai.azure.com"
end