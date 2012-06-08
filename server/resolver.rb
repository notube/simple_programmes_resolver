require 'rubygems'
require 'json/pure'
require 'net/http'
require 'uri'
require 'date'
require 'uri'
require 'cgi'
require 'open-uri'
gem 'dbi'
require "dbi"
gem 'dbd-mysql'
require 'pp'
       
      def connect_to_mysql()
         return DBI.connect('DBI:Mysql:epgs', 'user', 'pass')
      end

      def query(q)
        arr = []
        begin
          dbh = connect_to_mysql()
          query = dbh.prepare(q)
          query.execute()
          while row = query.fetch() do
             arr.push(row.to_a)
          end
          dbh.commit
          query.finish
          dbh.disconnect
      end

  return arr
end



      def resolve(req, res, dont_redirect)
        puts "in resolve "
        prog_url_start="http://www.bbc.co.uk/programmes/"
        res['Content-Type'] = 'text/javascript'
        res.status = 200
        #pp req.query_string
        result = []

        uris = []

# different types of uris
        crid=nil
        dvb=nil
        prog = nil
        pips = nil        

# other parameters
        start=nil
        startt = req.query["start"]
        utc = startt
        # make sure that start is in utc

        if startt
          if  startt.match(/Z$/)
            #ok. but since we store as local time we need to convert it
             ts = Time.parse(startt)
             # check if date indicates daylight savings time

             # this is messy. our db stores the times as it finds them 
             # which is Z if in UTC, or +01:00 if in BST

             t2 = Time.now
             t = t2.getlocal

             if !t.dst?
               utc = ts.utc.xmlschema()
             else
               ts = ts - 3600
               utc = ts.getlocal.xmlschema()
               utc = utc.gsub(/Z$/,"+01:00") #ugh but I can't see another way
               utc = utc.gsub(/\+00:00$/,"+01:00") #ugh but I can't see another way
             end
          else
            err =  "Error - start time should be in UTC"
            res.status = 404
            result=["404",nil,err]
            return res,result
          end
        end

        warnings = ""
        duration = nil
        duration = req.query["duration"]
        if(duration)
          warning = "#{warning}
Duration is not yet supported"
        end
        transmissionTime = nil
        transmissionTime = req.query["transmissionTime"]
        if(transmissionTime)
          warning = "#{warning}
transmissionTime is not yet supported fully"
        end

        eventid=nil
        eventid = req.query["eventid"]
        serviceid=nil
        serviceid = req.query["serviceid"]
        fmt = nil
        fmt = req.query["fmt"]

        # webrick won't let you have two parameters with the same name
        qs = req.query_string.to_s.split("&")
        qs.each do |q|
           r = q.split("=")
           k = r[0]
           if(r.length > 1)
              v = r[1]
              v= CGI::unescape(v)
              #puts "k / v: #{k} #{v}"
              if k.match(/^uri/)
                 uris.push(v)
                 if v.match(/^crid:/)
                   crid = v
                 end
                 if v.match(/^dvb:/)
                   dvb = v
                 end
                 if v.match(/^tag:feeds.bbc.co.uk/)
                   pips = v
                 end
                 if v.match(/^http:\/\/www.bbc.co.uk\/programmes\//)
                   prog = v
                 end
              end
           end
        end

        #pp uris

#dvb://<original_network_id>.<transport_stream_id>.<service_id> is channel url
#3005.1044.1004.233a.dvb.tvdns.net

        channel_urls = {
"3098.1041.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcone#service",
"3098.10bf.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbctwo#service",
"3098.10c0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcthree#service",
"3098.1100.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcnews#service",
"3098.1140.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcredbutton#service",
"3098.11c0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcfour#service",
"3098.1200.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/cbbcchannel#service",
"3098.1280.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcparliament#service",
"3098.1600.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/5live#service",
"3098.1640.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/5livesportsextra#service",
"3098.1680.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/6music#service",
"3098.16c0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio7#service",
"3098.1700.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/1xtra#service",
"3098.1740.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/asiannetwork#service",
"3098.1780.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/worldservice#service",
"3098.1a40.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio1#service",
"3098.1a80.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio2#service",
"3098.1ac0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio3#service",
"3098.1b00.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio4#service"
        }

        channel_txt = {
"3098.1041.1041.233a.dvb.tvdns.net"=>"bbcone",
"3098.10bf.1041.233a.dvb.tvdns.net"=>"bbctwo",
"3098.10c0.1041.233a.dvb.tvdns.net"=>"bbcthree",
"3098.1100.1041.233a.dvb.tvdns.net"=>"bbcnews",
"3098.1140.1041.233a.dvb.tvdns.net"=>"bbcredbutton",
"3098.11c0.1041.233a.dvb.tvdns.net"=>"bbcfour",
"3098.1200.1041.233a.dvb.tvdns.net"=>"cbbc",
"3098.1280.1041.233a.dvb.tvdns.net"=>"parliament",
"3098.1600.1041.233a.dvb.tvdns.net"=>"5live",
"3098.1640.1041.233a.dvb.tvdns.net"=>"5livesportsextra",
"3098.1680.1041.233a.dvb.tvdns.net"=>"6music",
"3098.16c0.1041.233a.dvb.tvdns.net"=>"radio7",
"3098.1700.1041.233a.dvb.tvdns.net"=>"1xtra",
"3098.1740.1041.233a.dvb.tvdns.net"=>"asiannetwork",
"3098.1780.1041.233a.dvb.tvdns.net"=>"worldservice",
"3098.1a40.1041.233a.dvb.tvdns.net"=>"radio1",
"3098.1a80.1041.233a.dvb.tvdns.net"=>"radio2",
"3098.1ac0.1041.233a.dvb.tvdns.net"=>"radio3",
"3098.1b00.1041.233a.dvb.tvdns.net"=>"radio4"

        }
        # look for the host
        # returns a MatchData object
        puts "HOST: #{req.host}"
        host = req.host
        host_chan = nil
#       host = "3098.1041.1041.233a.dvb.tvdns.net"##@@!! for testing only
        if host.match(/^([\da-f]{4})\.([\da-f]{4})\.([\da-f]{4})\.([\da-f]{4})(\.[^.]+)?\.(tvdns|radiodns)\.(org|net)$/i)
          if host.match("dvb://")
             host = host.gsub("dvb://","")
          end
          if channel_urls[host]
             host_chan = channel_txt[host]
             puts "found host #{host_chan}"
          else
             puts "no host match..."
          end
        end


# the logic is:
# if crid, just go ahead and look up that, resolve to progs
# if not crid
#  if dvb, look up that, resolve to progs
# if not dvb
#  if host and starttime, resolve to progs
#  if eventid and serviceid, resolve to progs
#  if pips or progs, return crid and dvb @@not done yet@@

        #dont_redirect = false #hack to make pips / progs work
        begin
          # new - if multiple crids and no redirect, just get those
          if(uris.length>1 && dont_redirect && crid)

            processed_uris = []

            uris.each do |u|
                u.downcase!
                u.gsub!(/#\d*$/,"")
                processed_uris.push('"'+u+'"')
            end
            pu = processed_uris.join(",")
            q = "select distinct 
pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end from todays_epg left 
join pid_data on (todays_epg.start = pid_data.start and todays_epg.channel = pid_data.dvb_service_title) where 
crid in (#{pu}) and pid <> \"NULL\";"
            puts q  
            crid = nil
          end

          # use the service to get the query
          if crid
            uri = crid
            # downcase (at Matt's request but seems sensible)
            uri.downcase!
            # remove any stray hash-numbers
            uri.gsub!(/#\d*$/,"")
            # make the sameas query

            q = "select distinct 
pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end from todays_epg left 
join pid_data on (todays_epg.start = pid_data.start and todays_epg.channel = pid_data.dvb_service_title) where 
crid='#{uri}';"

            puts "q is #{q}"
          else
            if dvb
              uri = dvb
              # make the sameas query
            q = "select distinct pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end from todays_epg left join pid_data on (todays_epg.start = 
pid_data.start and todays_epg.channel = pid_data.dvb_service_title) where dvb='#{uri}';"

            else
               if host_chan && utc

                  utc.gsub!("T"," ")

                  # regional variations
                  if(host_chan.match("bbcone") ||host_chan.match("bbctwo") || host_chan.match("radio4") ) 

                     q = "select pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end from todays_epg left join pid_data on (todays_epg.start = pid_data.start
and todays_epg.channel = pid_data.dvb_service_title) where pid_data.service =
'#{host_chan}' and todays_epg.start='#{utc}'"

                  end
               else
                 if eventid && serviceid
                    q = "select distinct pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end from todays_epg left join pid_data on (todays_epg.start = 
pid_data.start and todays_epg.channel = pid_data.dvb_service_title) where dvb REGEXP '#{serviceid}.*#{eventid}';"

                 else
               
                   if pips || prog
                     if prog
                       puts "prog!"
                       dont_redirect = true
                       uri = prog
                       uri.gsub!(prog_url_start,"")
                       uri.gsub!("#programme","")
                     end
                     if pips
                       pid = pips.gsub("tag:feeds.bbc.co.uk,2008:PIPS:","")
                       uri = pid
                     end

                     q = "select distinct pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end from todays_epg left join pid_data on (todays_epg.start = pid_data.start
and todays_epg.channel = pid_data.dvb_service_title) where pid = '#{uri}';"                     
                     puts "q2 is #{q}"

                   end
                 end
               end
            end
          end
          p = nil

          puts "q3 is #{q}"


          if host_chan && transmissionTime
            result = []
            #find the channel
            #this is hacky
            chan = channel_txt[host]
            if(transmissionTime=="")

              t2 = Time.now
              t = t2.getlocal

              if !t.dst?
                 utc = t.utc.xmlschema()
              else
                 t = t - 3600
                 utc = t.getlocal.xmlschema()
                 utc = utc.gsub(/Z$/,"+01:00") #ugh but I can't see another way
                 utc = utc.gsub(/\+00:00$/,"+01:00") #ugh but I can't see another way
              end
              transmissionTime = utc
            end
            if(transmissionTime)
               transmissionTime.gsub!("T"," ")
            end
              # for mo: get dvb and crid
              q = "select distinct pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end 
from todays_epg left join pid_data on (todays_epg.start = pid_data.start
and todays_epg.channel = pid_data.dvb_service_title) where service =
'#{chan}' and todays_epg.start <= '#{transmissionTime}' && todays_epg.end > '#{transmissionTime}'"

              puts "QQ[1]#{q}"

              result = query(q)

          else
            puts "odd - q is #{q}"
            result = query(q)
          end
          if result.length>0
             z = result[0] #we just take the first for now

             if(z && z.length>0)
               p = prog_url_start+z[0]+"#programme"
               res.status = 301
               if dont_redirect
                  res.status = 200
                  p = prog_url_start+z[0]+"#programme"
                  # process results
                  #pid,crid,dvb,pid_data.title,service,service_title,description,pid_data.start,pid_data.end
                  rz = []
                  result.each do |r|
                     pid = r[0]
                     rz.push({"p"=>"#{prog_url_start}#{pid}","url"=>"#{prog_url_start}#{pid}","pid"=>r[0],"crid"=>r[1],"dvb"=>r[2],"title"=>r[3],"service"=>r[4],"service_title"=>r[5],"description"=>r[6],"start"=>r[7],"end"=>r[8]})
                  end
                  result = rz
                  #pp rz
               else
                 if (fmt && fmt=="rdf")
                   p = p.gsub("#programme",".rdf")
                   res.set_redirect(HTTPStatus::MovedPermanently, p)
                 else
                   p = prog_url_start+z[0]+"#programme"
                   res.set_redirect(HTTPStatus::MovedPermanently, p)
                 end
               end
             else
               res.status = 404
               result=["404","No match found",warnings]
             end
          else
             res.status = 404
             result=["404","No results found - service has failed",warnings]
          end      
        rescue WEBrick::HTTPStatus::MovedPermanently=>e
          result=["301",{"uri"=>p},warnings]
        rescue Exception=>e
          result=["404",e,warnings]
          res.status = 404
          puts e.inspect
          puts e.backtrace
        end
        return res,result
      end

      def whatsPlaying(serv,q)
        useragent = "NotubeMiniCrawler/0.1"
        z = serv + "?" + q

        u =  URI.parse z
        puts "asking for #{z}"
        req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
        req = Net::HTTP::Get.new( u.path+ '?' + u.query ) 
#        req.basic_auth 'notube', 'ebuton'
        begin
          res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
        end
        return res2.body
      end
     

