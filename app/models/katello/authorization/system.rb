#
# Copyright 2014 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

module Katello
module Authorization::System
  extend ActiveSupport::Concern

  module ClassMethods
    # returns list of virtual permission tags for the current user
    def list_tags
      select('id,name').all.collect { |m| VirtualTag.new(m.id, m.name) }
    end

    def readable_search_filters(org)
      {:or => [
          {:terms => {:environment_id => KTEnvironment.systems_editable(org).collect { |item| item.id } }},
          {:terms => {:host_collection_id => HostCollection.content_hosts_editable(org).collect { |item| item.id } }},
        ]
      }
    end

    def readable(org)
      fail "scope requires an organization" if org.nil?
      if org.systems_readable?
        where(:environment_id => org.kt_environment_ids) #list all systems in an org
      else #just list for environments the user can access
        where_clause = "#{System.table_name}.environment_id in (#{KTEnvironment.systems_readable(org).select(:id).to_sql})"
        where_clause += " or "
        where_clause += "#{SystemHostCollection.table_name}.host_collection_id in (#{HostCollection.content_hosts_readable(org).select(:id).to_sql})"
        joins("left outer join #{SystemHostCollection.table_name} on #{System.table_name}.id =
                                    #{SystemHostCollection.table_name}.system_id").where(where_clause)
      end
    end

    def editable(org)
      if org.systems_editable?
        where(:environment_id => org.kt_environment_ids)
      else
        where_clause = "#{System.table_name}.environment_id in (#{KTEnvironment.systems_editable(org).select(:id).to_sql})"
        where_clause += " or "
        where_clause += "#{SystemHostCollection.table_name}.host_collection_id in (#{HostCollection.content_hosts_editable(org).select(:id).to_sql})"
        joins("left outer join #{SystemHostCollection.table_name} on #{System.table_name}.id =
                                    #{SystemHostCollection.table_name}.system_id").where(where_clause)
      end
    end

    def deletable(org)
      if org.systems_deletable?
        where(:environment_id => org.kt_environment_ids)
      else
        where_clause = "#{System.table_name}.environment_id in (#{KTEnvironment.systems_deletable(org).select(:id).to_sql})"
        where_clause += " or "
        where_clause += "#{SystemHostCollection.table_name}.host_collection_id in (#{HostCollection.content_hosts_deletable(org).select(:id).to_sql})"
        joins("left outer join #{SystemHostCollection.table_name} on #{System.table_name}.id =
                                    #{SystemHostCollection.table_name}.system_id").where(where_clause)
      end
    end

    def any_readable?(org)
      org.systems_readable? ||
        KTEnvironment.systems_readable(org).count > 0 ||
        HostCollection.content_hosts_readable(org).count > 0
    end

    # TODO: these two functions are somewhat poorly written and need to be redone
    def any_deletable?(env, org)
      if env
        env.systems_deletable? || org.host_collections.any?{|g| g.content_hosts_deletable?}
      else
        org.systems_deletable? || org.host_collections.any?{|g| g.content_hosts_deletable?}
      end
    end

    def registerable?(env, org, content_view = nil)
      subscribable = content_view ? content_view.subscribable? : true
      registerable = (env || org).systems_registerable?
      subscribable && registerable
    end

    def any_systems_editable?(systems)
      systems.collect{ |s| false unless s.editable? }.compact.empty?
    end

    def any_systems_deletable?(systems)
      systems.collect{ |s| false unless s.deletable? }.compact.empty?
    end
  end

  included do
    def readable?
      sg_readable = !Katello::HostCollection.content_hosts_readable(self.organization).where(:id => self.host_collection_ids).empty?
      environment.systems_readable? || sg_readable
    end

    def editable?
      sg_editable = !Katello::HostCollection.content_hosts_editable(self.organization).where(:id => self.host_collection_ids).empty?
      environment.systems_editable? || sg_editable
    end

    def deletable?
      sg_deletable = !Katello::HostCollection.content_hosts_deletable(self.organization).where(:id => self.host_collection_ids).empty?
      environment.systems_deletable? || sg_deletable
    end
  end

end
end
