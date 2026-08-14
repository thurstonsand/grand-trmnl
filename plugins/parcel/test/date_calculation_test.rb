#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "liquid"
require "trmnl/liquid"

source = File.read File.expand_path("../src/shared.liquid", __dir__)
today_assignment = source.lines.find { it.include?("assign today_date") }
raise "today_date assignment missing" unless today_assignment

timezone = "America/New_York"
expected_date = TZInfo::Timezone.get(timezone).now.to_date + 3
template = Liquid::Template.parse <<~LIQUID, environment: TRMNL::Liquid.new
  #{today_assignment}{% assign today_epoch = today_date | date: "%s" | plus: 0 %}
  {% assign expected_epoch = expected_date | date: "%s" | plus: 0 %}
  {% assign days = expected_epoch | minus: today_epoch | plus: 43200 | divided_by: 86400 %}
  {{ today_date }}|{{ days }}
LIQUID

actual_date, days = template.render(
  "expected_date" => expected_date.iso8601,
  "trmnl" => {
    "user" => {
      "time_zone" => "Eastern Time (US & Canada)",
      "time_zone_iana" => timezone
    }
  }
).strip.split("|")

raise "today_date was #{actual_date.inspect}, expected #{expected_date - 3}" unless actual_date == (expected_date - 3).iso8601
raise "days-until-delivery was #{days.inspect}, expected 3" unless days == "3"

puts "date calculation: today=#{actual_date}, three-day ETA=3"
