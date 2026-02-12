ENGINES = {
  "shiny_json_logic" => { "class" => "ShinyJsonLogic", "requirement" => "shiny_json_logic" },
  "json_logic_ruby" => { "class" => "JsonLogic::Evaluator", "requirement" => "json_logic" },
  "json-logic-rb" => { "class" => "JsonLogic", "requirement" => "json_logic" },
  "json_logic" => { "class" => "JSONLogic", "requirement" => "json_logic" },
}

begin
  require ENGINES.dig(ENV["LIBRARY"], "requirement")
rescue StandardError => e
  puts "Could not load library #{ENV["LIBRARY"]}. Make sure it's installed."
  puts e.message
  exit 1
end
require "json"

def load_test_suite
  test_files = JSON.parse(File.read("../suites/index.json"))
  test_files.map do |file_name|
    {
      "test_suite" => file_name,
      "cases" => JSON.parse(File.read("../suites/#{file_name}"))
    }
  end
end

def run_engine_tests(engine:, suite:)
  passed = 0
  total = 0

  suite.each do |case_data|
    next unless case_data.is_a?(Hash)

    total += 1
    expects_error = case_data.key?("error")

    puts "Running test #{total}: #{case_data["description"]}"
    result = engine.apply(case_data["rule"], case_data["data"])
    if expects_error
      # Expected an error but got a result
      puts "Test #{total} failed. Expected error, got #{result}"
    elsif result == case_data["result"]
      passed += 1
    else
      puts "Test #{total} failed. Expected #{case_data["result"]}, got #{result}"
    end
  rescue StandardError => e
    if expects_error
      expected_type = case_data.dig("error", "type")
      if e.respond_to?(:type) && e.type == expected_type
        passed += 1
      else
        puts "Test #{total} failed. Expected error type #{expected_type}, got #{e.respond_to?(:type) ? e.type : e.class}"
      end
    else
      puts "Test #{total} failed. Expected #{case_data["result"]}, error #{e.message} was raised"
    end
    next
  end

  [passed, total]
end

def run_suite_tests(summary:, suite_name:, suite:)
  puts "\nRunning suite: #{suite_name}"

  engine_name = ENV["LIBRARY"]
  engine = solve_engine(engine_name)

  passed, total = run_engine_tests(engine: engine, suite: suite)
  add_result(summary, suite_name, engine_name, passed, total)
end

def solve_engine(engine_name)
  engine_class = Object.const_get(ENGINES.dig(engine_name, "class"))
  case engine_name
  when "shiny_json_logic", "json-logic-rb", "json_logic"
    engine_class
  when "json_logic_ruby"
    engine_class.new
  else
    raise "Unknown engine: #{engine_name}"
  end
end

def load_existing_summary(filename:)
  JSON.parse(File.read(filename)).tap do |summary|
    summary["totals"][ENV["LIBRARY"]] = {"passed" => 0, "total" => 0}
  end
rescue Errno::ENOENT, JSON::ParserError
  {
    "test_suites" => {},
    "totals" => { ENV["LIBRARY"] => {"passed" => 0, "total" => 0} },
  }
end

def add_result(summary, suite_name, engine, passed, total)
  summary["test_suites"][suite_name] ||= {}
  summary["test_suites"][suite_name][engine] = {
    "passed" => passed,
    "total" => total,
  }

  summary["totals"][engine]["passed"] += passed
  summary["totals"][engine]["total"] += total
end

def main
  suites = load_test_suite
  puts "Successfully loaded #{suites.size} test suites"

  results_file = "../results/ruby.json"
  summary = load_existing_summary(filename: results_file)

  suites.each do |suite|
    run_suite_tests(summary: summary, suite_name: suite["test_suite"], suite: suite["cases"])
  end
rescue StandardError => e
  puts "An error occurred: #{e.message}"
  puts e.full_message
ensure
  File.write(results_file, JSON.pretty_generate(summary))
  p "Tests with #{ENV["LIBRARY"]} have finished. Results saved to #{results_file}"
end

if __FILE__ == $0
  main
end

