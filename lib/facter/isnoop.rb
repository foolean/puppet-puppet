# isnoop.rb
#
# This fact exposes whether  puppet is running with --noop or not.  First, the
# 'isnoop' facter variable is set which can be read from within any manifest.
# Second the 'PUPPET_NOOP' environment variable is set which can be read from
# within any script running via the prerun_command or postrun_command options. 
#
# CREDIT
#   The main detection logic was taken from the noop handling
#   in the various ruby scripts that make up the body of Puppet.
#
###############################################################################
Facter.add("isnoop") do
    setcode do
        if defined?(@noop)
           @noop
           if @noop
               ENV['PUPPET_NOOP'] = 'true'
           else
               ENV['PUPPET_NOOP'] = 'false'
           end
        else
           Puppet[:noop]
           if Puppet[:noop]
               ENV['PUPPET_NOOP'] = 'true'
           else
               ENV['PUPPET_NOOP'] = 'false'
           end
        end
    end
end
