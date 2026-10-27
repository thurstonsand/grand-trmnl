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

# A non-UTC process zone catches window math that leans on the server's timezone.
ENV["TZ"] = "Asia/Tokyo"
shared = Liquid::Template.parse "#{source}\n{{ bin_when }}|{{ bin_recycling }}", environment: TRMNL::Liquid.new
pickups = {
  "events" => [
    { "day" => "2026-10-28", "flags" => [{ "name" => "Garbage", "event_type" => "pickup" }] },
    { "day" => "2026-11-04", "flags" => [{ "name" => "Garbage", "event_type" => "pickup" },
                                         { "name" => "Recycling", "event_type" => "pickup" }] },
    { "day" => "2026-11-11", "flags" => [{ "name" => "holiday", "event_type" => nil }] },
    { "day" => "2026-11-12", "flags" => [{ "name" => "Garbage", "event_type" => "pickup" }] }
  ]
}
{
  "2026-10-27 11:59:00 -04:00" => "|false",
  "2026-10-27 12:00:00 -04:00" => "tonight|false",
  "2026-10-27 23:30:00 -04:00" => "tonight|false",
  "2026-10-28 11:59:00 -04:00" => "today|false",
  "2026-10-28 12:00:00 -04:00" => "|false",
  "2026-11-03 19:00:00 -05:00" => "tonight|true",
  "2026-11-10 13:00:00 -05:00" => "|false",
  "2026-11-11 13:00:00 -05:00" => "tonight|false"
}.each do |local, expected|
  now = Time.new(local)
  actual = shared.render(
    "IDX_1" => pickups,
    "trmnl" => {
      "system" => { "timestamp_utc" => now.to_i },
      "user" => { "time_zone_iana" => timezone, "utc_offset" => now.utc_offset }
    }
  ).lines.last.strip
  raise "bin reminder at #{local} was #{actual.inspect}, expected #{expected.inspect}" unless actual == expected
end

puts "bin reminder: noon-to-noon window holds at 8 instants"
