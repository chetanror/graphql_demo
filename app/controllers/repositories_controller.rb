class RepositoriesController < ApplicationController
  require 'csv' 

  IndexQuery = GitHub::Client.parse <<-'GRAPHQL'
    query($after: String){
    search(query: "org:google", type: REPOSITORY, first: 100, after: $after) {
      repositoryCount
      pageInfo {
        endCursor
        startCursor
        hasNextPage
      }
      edges {
        node {
          ... on Repository {
            name
            createdAt
            primaryLanguage {
              name
            }
            
            
          }
        }
      }
    }
  }
  GRAPHQL
  
  # GET list of all repositories
  def index
    fetch_repositories #fetch all repositories of google organisation
    find_top_least(@repo) #find out top 5 and least 5 languages used by google organisation
  end

  # GET export to CSV file
  def export
    fetch_repositories #fetch all repositories of google organisation
    file = "#{Rails.root}/public/repositories.csv"
    headers = ["Name", "language", "CreatedAt"]
    CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
      @repo.each do |repo| 
      writer << [repo[:name],repo[:language], repo[:created_at]] 
      end
    end

    send_file(file, type: "text/csv", filename: "repositories.csv", disposition: "attachment")
  end

  def fetch_repositories
    @repo, has_next, after = [], true, nil
    while has_next
      data = query IndexQuery, after: after
      has_next = data.search.page_info.has_next_page?
      after = data.search.page_info.end_cursor
      JSON.parse(data.to_json).first.second["search"]["edges"].each do |node |
        language = node["node"]["primaryLanguage"]["name"] rescue ""
        @repo << { name: node["node"]["name"], language: language, created_at: node["node"]["createdAt"] }
      end
      puts @repo.count
    end
  end

  def find_top_least(repo)
    languages = repo.map{|x| x[:language]}.reject { |c| c.empty? }
    occurances =  languages.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{ |k, v| [v, k]}.reverse
    @top_languages = occurances.first(5)
    @least_languages = occurances.last(5)
    puts "top languages->>> #{@top_languages}"
    puts "least languages->>> #{@least_languages}"
  end
end
