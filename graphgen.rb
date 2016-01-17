require 'chartkick'
require 'pry'
require 'haml'
require 'yaml'



# module Haml
#   module Helpers
#     include Chartkick::Helper
#   end
# end

# def do_it times
#   "Now" * times
# end

class HamlScope
  include Chartkick::Helper

  def chart_daily
    chart_dump "Daily", "24h"
  end

  def chart_weekly
    chart_dump "Weekly", "week"
  end

  def chart_dump master_title, dir
    data = load_data dir

    #### By Category:
    ## Find the categories and turn them into named data pits
    categories_list = data.each_with_object([]) do |item, memo|
      memo << item[:stats][:by_category].keys
    end.flatten.uniq.sort do |a,b|
      a && b ? a <=> b : a ? -1 : 1
    end

    ## Get the data

    lines = {}

    lines["By Count"] = {
      yAxis: "Count",
      data: select_chart_stats(data, categories_list) do |category|
        category[:count]
      end
    }

    lines["By Comment Count, Total over period"] = {
      yAxis: "Count",
      data: select_chart_stats(data, categories_list) do |category|
        category[:comments][:sum]
      end
    }

    lines["By Votes, Total over period"] = {
      yAxis: "Count",
      data: select_chart_stats(data, categories_list) do |category|
        category[:scores][:sum]
      end
    }

    lines["By Max Votes"] = {
      yAxis: "Upvotes",
      data: select_chart_stats(data, categories_list) do |category|
        category[:scores][:max]
      end
    }

    lines["By Q3 Votes"] = {
      yAxis: "Upvotes",
      data: select_chart_stats(data, categories_list) do |category|
        category[:scores][:q3]
      end
    }

    lines["By Median Votes"] = {
      yAxis: "Upvotes",
      data: select_chart_stats(data, categories_list) do |category|
        category[:scores][:q2]
      end
    }

    lines["By Q1 Votes"] = {
      yAxis: "Upvotes",
      data: select_chart_stats(data, categories_list) do |category|
        category[:scores][:q1]
      end
    }

    lines["By Q3 Comment Count"] = {
      yAxis: "Comments",
      data: select_chart_stats(data, categories_list) do |category|
        category[:comments][:q3]
      end
    }

    lines["By Median Comment Count"] = {
      yAxis: "Comments",
      data: select_chart_stats(data, categories_list) do |category|
        category[:comments][:q1]
      end
    }

    lines["By Q1 Comment Count"] = {
      yAxis: "Comments",
      data: select_chart_stats(data, categories_list) do |category|
        category[:comments][:q1]
      end
    }

    out = ""
    lines.each do |subtitle,value|
      out += line_chart(
        value[:data],
        height: "500px",
        library: {
          yAxis: {
            title: {
              text: value[:yAxis]
            }
          },
          title: {
            text: master_title
            },
          subtitle: {
            text: subtitle
            },
          tooltip: {
              crosshairs: true,
              shared: true
          }})
    end
    out
  end

  def chart_test
    line_chart(
      [ { name: "t",
          color: "red",
          data: [1,2,3,4,5].each_with_object({}) do |i, memo|
            memo["#{i}"] = i
          end
      },{ name: "t2",
          color: "yellow",
          data: [1,2,3,4,5].each_with_object({}) do |i, memo|
            memo["#{i}"] = i/2
          end
      }],
      discrete: true,
      colors: ["black"],
      library: {
        title: {
          text: "Hello"
          },
        subtitle: {
          text: "World"
          },
        tooltip: {
            crosshairs: true,
            shared: true
          }}
    )
  end

  def get_binding
    return binding()
  end



  private

    # maps a category/general to a value by using a block
    def select_chart_stats all_data, titles, &block
      data_pits = titles_to_data_pits(titles)
      general = {
        name: "EVERYTHING",
        color: "red",
        data: {}
      }

      all_data.each do |file_data|
        time = DateTime.parse file_data[:meta][:time_utc]

        # general
        value = yield file_data[:stats][:general]
        general[:data][time.to_s] = value

        # each value
        data_pits.each do |k,v|
          data = file_data[:stats][:by_category][k]
          if data
            value = yield data
            v[:data][time.to_s] = value
          end
        end
      end

      # map, and add general to the list
      data_array = data_pits.map { |k,v| v }
      data_array << general
      data_array
    end

    # maps a category/general to a value by using a block
    def select_chart_stats_diff_from_general all_data, titles, &block
      data_pits = titles_to_data_pits(titles)
      general = {
        name: "EVERYTHING",
        color: "red",
        data: {}
      }

      all_data.each do |file_data|
        time = DateTime.parse file_data[:meta][:time_utc]

        # general
        general_value = yield file_data[:stats][:general]
        general[:data][time.to_s] = 0

        # each value
        data_pits.each do |k,v|
          data = file_data[:stats][:by_category][k]
          if data
            value = yield data
            v[:data][time.to_s] = value - general_value
          end
        end
      end

      # map, and add general to the list
      data_array = data_pits.map { |k,v| v }
      data_array << general
      data_array
    end

    def titles_to_data_pits titles
      titles.each_with_object({}) do |category, output|
        output[category] = {
          name: category,
          data: {}
        }
      end
    end

    def load_data dir
      Dir["stats/#{dir}/*"].map do |filename|
        YAML.load_file filename
      end
    end
end

tScope = HamlScope.new()
tBinding = tScope.get_binding


tBase = Haml::Engine.new(
  File.read('graphs/base.haml'))
tGraphs = Haml::Engine.new(
  File.read('graphs/graphs.haml'))

File.open('out/graphs.html', 'w') do |file|
  output = tBase.render tBinding
  file << output
end