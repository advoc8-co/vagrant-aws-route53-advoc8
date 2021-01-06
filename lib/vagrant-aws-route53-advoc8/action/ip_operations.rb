require 'aws-sdk'

module VagrantPlugins
  module AwsRoute53Advoc8
    module Action
      class IpOperations
        private
        def config(environment)
          config          = environment[:machine].config
          provider_config = environment[:machine].provider_config

          access_key_id     = provider_config.access_key_id
          secret_access_key = provider_config.secret_access_key
          region            = provider_config.region
          instance_id       = environment[:machine].id
          hosted_zone_id    = config.route53.hosted_zone_id
          record_set        = config.route53.record_set

          return access_key_id, hosted_zone_id, instance_id, record_set, region, secret_access_key
        end

        def set(options)
          ::Aws.config(access_key_id: options[:access_key_id], secret_access_key: options[:secret_access_key], region: options[:region])

          ec2 = ::Aws.ec2
          public_ip = options[:public_ip] || ec2.instances[options[:instance_id]].public_ip_address

          record_sets = ::Aws::Route53::HostedZone.new(options[:hosted_zone_id]).rrsets
          record_set  = record_sets[*options[:record_set]]
          record_set.resource_records = [{ value: public_ip }]
          record_set.update

          if block_given?
            yield options[:instance_id], public_ip, options[:record_set]
          end

          nil
        end
      end
    end
  end
end