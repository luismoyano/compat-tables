require ENV["library"] || "shiny_json_logic_ruby"
require "json"

ENGINES = {
  "shiny_json_logic_ruby" => "ShinyJsonLogic",
  "json_logic_ruby" => "JsonLogic",
  "json_logic_rb" => "JsonLogicRB"
}

def load_test_suite
  test_files = JSON.parse(File.read("../suites/index.json"))
  test_files.map do |file_name|
    {
      test_suite: file_name,
      cases: JSON.parse(File.read("../suites/#{file_name}")).with_indifferent_access
    }
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

  engine_name = ENV["LIBRARY"] || "shiny_json_logic_ruby"
  engine = ENGINES[engine_name].constantize

  passed, total = run_engine_tests(engine: engine, suite: suite)
  add_result(summary, suite_name, engine_name, passed, total)
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

def add_result(summary, suite_name, engine, passed, total)
  summary["test_suites"][suite_name] ||= {}
  summary["test_suites"][suite_name][engine] = {
    "passed" => passed,
    "total" => total,
  }

  summary["totals"][engine] ||= {"passed" => 0, "total" => 0}
  summary["totals"][engine]["passed"] += passed
  summary["totals"][engine]["total"] += total
end

def main
  suites = load_test_suite
  puts "Successfully loaded #{suites.size} test suites"

  results_file = "../results/ruby.json"
  summary = load_existing_summary(filename: results_file)

  suites.each do |suite|
    run_suite_tests(summary: summary, suite_name: suite[:suite_name], suite: suite[:cases])
  end

  File.write("../results/ruby.json", JSON.pretty_generate(summary))
end

if __FILE__ == $0
  main
end

