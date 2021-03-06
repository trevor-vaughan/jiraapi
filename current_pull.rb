# jira_pull.rb 
# this file pulls the jira tickets for the CURRENT sprint 
# and writes the data to a comma-separated file
# note that we get 2 files - one just has the tasks, 
# the second _wparent appends the parent with a slash
# so description on jirapull.csv is "task 1"
# and on jirapull_wparent.csv is "parent/task 1"
require 'rest-client'
require 'json'

# first create two .csv files - one with the parent appended, the other without - ensure the field names are OK
pullfile = File.open("jirapull.csv", "w")
parentpullfile = File.open("jirapull_wparent.csv", "w")
pullfile.puts( "Issue id,Parent id,Summary,Issue Type,Story Points,Sprint,Description,Assignee")
parentpullfile.puts("Issue id,Parent id,Summary,Issue Type,Story Points,Sprint,Description,Assignee")

# here is our jira instance
project_key = "ABC"
jira_url = "https://simp-project.atlassian.net/rest/api/2/search?"

#find current sprint
filter = "jql=sprint%20in%20openSprints()"

# set a max # results - defaults to 50 (we can switch this to a loop later)
maxresults = 250
filter = "#{filter}&maxResults=#{maxresults}"

# call the code
response = RestClient.get(jira_url+filter)
if(response.code != 200)
  raise "Error with the http request!"
end

data = JSON.parse(response.body)
#puts "current data is #{data}"

data['issues'].each do |issue|
  points = issue['fields']['customfield_10005']
  points = points.to_i
  issuekey = issue['key']
  summary = issue['fields']['summary']
  desc = issue['fields']['description']
  # substitute apostrophe for quote
  if (desc != nil)
    temp = desc.gsub("\"","\'")
    desc = temp
  end

  # see if it has a parent, and if so, display it"
  if issue['fields']['parent'] != nil
    parent = issue['fields']['parent']['key']
  else
    parent = "#{issuekey}."
  end

  # calculate the sprint by breaking the "sprint=" out of the sprint attributes string 
  sprintdata = issue['fields']['customfield_10007']
  if sprintdata != nil
    idstring = sprintdata[0]
    idstringname = idstring.slice(idstring.index('name='),idstring.size)
    comma=idstringname.index(',')-1
    sprintid=idstringname[5..comma]
  else
    sprintid = ""
  end

  # get type
  if issue['fields']['issuetype'] != nil
    issuetype = issue['fields']['issuetype']['name']
  else
    issuetype = ""
  end

  # get assignee
  if issue['fields']['assignee'] != nil
    assignee = issue['fields']['assignee']['name']
  else
    assignee = ""
  end

  # write to files 
  pullfile.puts( "#{issuekey},#{parent},\"#{summary} (#{issuekey})\",#{issuetype},#{points},#{sprintid},\"#{desc}\",#{assignee}" )
  parentpullfile.puts( "#{issuekey},#{parent},\"#{parent}/#{summary} (#{issuekey})\",#{issuetype},#{points},#{sprintid},\"#{desc}\",#{assignee}" )


  # here for later -- if we get stuck and need to find another issue attribute, use this as a starting point 
  issue['fields'].each do |ifield|
#    puts "field: #{ifield}"
#    puts "value: #issue['fields'][ifield]"
  end
end




