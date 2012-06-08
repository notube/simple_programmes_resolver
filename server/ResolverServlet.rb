   require 'webrick'
   require 'webrick/accesslog'
   include WEBrick
   require 'resolver.rb'

   class ResolverServlet < HTTPServlet::AbstractServlet

      def do_OPTIONS(req, res)
# Specify domains from which requests are allowed
        res["Access-Control-Allow-Origin"]="*"

# Specify which request methods are allowed
        res["Access-Control-Allow-Methods"] = "GET, POST"

# Additional headers which may be sent along with the CORS request
# The X-Requested-With header allows jQuery requests to go through
        res["Access-Control-Allow-Headers"]="X-Requested-With, Origin"

# Set the age to 1 day to improve speed/caching.
        res["Access-Control-Max-Age"]="86400"
        res.body=""
        res.status = 200

      end
      def do_POST(req, res)
        return do_GET(req, res)
      end
      def do_GET(req, res)
       begin
         
         noredirect = req.query["noredirect"]
         param = req.query["param"]
         dont_redirect = false
         if noredirect 
            puts "ok"
#            result[0]="200"
#            res.status = 200
            dont_redirect = true
         else
            puts "nok"
         end
         res,result = resolve(req,res, dont_redirect)
         puts result.class
         if(param)
           res.body = param+"("+JSON.pretty_generate(result)+")"
         else
           res.body = JSON.pretty_generate(result)
         end
       rescue Exception=>e
          puts e.inspect
          puts e.backtrace
       end
# Specify domains from which requests are allowed
       res["Access-Control-Allow-Origin"]="*"

# Specify which request methods are allowed
       res["Access-Control-Allow-Methods"] = "GET, POST"

# Additional headers which may be sent along with the CORS request
# The X-Requested-With header allows jQuery requests to go through
       res["Access-Control-Allow-Headers"]="X-Requested-With, Origin"

# Set the age to 1 day to improve speed/caching.
       res["Access-Control-Max-Age"]="86400"

      end

      # cf. http://www.hiveminds.co.uk/node/244, published under the
      # GNU Free Documentation License, http://www.gnu.org/copyleft/fdl.html

      @@instance = nil
      @@instance_creation_mutex = Mutex.new


      def ResolverServlet.get_instance( config, *options )
         load __FILE__
         ResolverServlet.new config, *options
      end

      def self.get_instance(config, *options)
         #pp @@instance
         @@instance_creation_mutex.synchronize {
            @@instance = @@instance || self.new(config, *options) }
      end

   end


