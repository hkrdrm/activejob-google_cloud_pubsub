require 'active_support/core_ext/module/attribute_accessors'
require 'activejob-google_cloud_pubsub/pubsub_extension'
require 'concurrent'
require 'google/cloud/pubsub'
require 'json'
require 'logger'

module ActiveJob
  module GoogleCloudPubsub
    class Adapter
      using PubsubExtension

      cattr_accessor(:logger) { Logger.new($stdout) }

      def initialize(async: true, pubsub: Google::Cloud::Pubsub.new)
        @executor = async ? :io : :immediate
        @pubsub   = pubsub
      end

      def enqueue(job, attributes = {})
        Concurrent::Promise.execute(executor: @executor) {
          @pubsub.topic_for(job.queue_name).publish JSON.dump(job.serialize), attributes
        }.rescue {|e|
          logger.error e
        }
      end

      def enqueue_at(job, timestamp)
        enqueue job, timestamp: timestamp
      end
    end
  end
end

require 'active_job'

ActiveJob::QueueAdapters::GoogleCloudPubsubAdapter = ActiveJob::GoogleCloudPubsub::Adapter
