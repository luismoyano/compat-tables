require ENV["library"] || "shiny_json_logic_ruby"
require "json"

ENGINES = {
  **({ "shiny_json_logic_ruby" => ShinyJsonLogic } if defined?(ShinyJsonLogic)),
  **({ "json_logic_ruby" => JsonLogic } if defined?(JsonLogic)),
  **({ "json_logic_rb" => JsonLogicRB } if defined?(JsonLogicRB)),
}

def load_test_suite
  test_files = JSON.parse(File.read("../suites/index.json"))
  test_files.map do |file_name|
    JSON.parse(File.read("../suites/#{file_name}")).with_indifferent_access
  end
end

def run_engine_tests(engine:, suite:)
  passed = 0
  total = 0

  suite.each_with_object(total) do |case_data, index|
    next unless case_data.is_a?(Hash)

    index += 1

    puts "Running test #{index}: #{case_data[:description]}"
    result = engine.apply(case_data[:rule], case_data[:data])
    if result == case_data[:result]
      passed += 1
    else
      puts "Test #{index} failed. Expected #{case_data[:result]}, got #{result}"
    end
  end

  [passed, total]
end

def run_suite_tests(summary:, suite_name:, suite:)
  puts "\nRunning suite: #{suite_name}"

  engine = ENGINES.fetch(ENV["LIBRARY"], "shiny_json_logic_ruby")

  passed, total = run_engine_tests(engine:, suite:)
  summary.add_result(suite_name, engine, passed, total)
end

def load_existing_summary(filename:)
  JSON.parse(File.read(filename))
rescue Errno::ENOENT, JSON::ParserError
  {
    "test_suites" => {},
    "totals" => {},
    "timestamp" => [],
    "python_version" => []
  }
end

def main
  suites = load_test_suite
  puts "Successfully loaded #{suites.size} test suites"

  summary = "" # TODO

  results_file = "../results/ruby.json"
  existing_results = load_existing_summary(filename: results_file)
  # summary.load_existing_results(existing_results)

  suites.each_with_index do |suite, idx|
    suite_name = "suite_#{idx + 1}"
    run_suite_tests(summary: summary, suite_name: suite_name, suite: suite)
    # Save Summary
  end
end

if __FILE__ == $0
  main
end

