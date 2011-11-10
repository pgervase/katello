#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

class SystemPackagesController < ApplicationController
  include AutoCompleteSearch

  before_filter :find_system, :except =>[:index, :auto_complete_search, :items, :environments, :env_items, :bulk_destroy, :new, :create]
  before_filter :authorize

  def rules
    edit_system = lambda{System.find(params[:system_id]).editable?}
    read_system = lambda{System.find(params[:system_id]).readable?}
    env_system = lambda{@environment.systems_readable?}
    any_readable = lambda{System.any_readable?(current_organization)}
    delete_systems = lambda{true}
    register_system = lambda { System.registerable?(@environment, current_organization) }

    {
      :index => any_readable,
      :create => register_system,
      :new => register_system,
      :items => any_readable,
      :auto_complete_search => any_readable,
      :environments => env_system,
      :env_items => env_system,
      :subscriptions => read_system,
      :update_subscriptions => edit_system,
      :packages => read_system,
      :more_packages => read_system,
      :update => edit_system,
      :edit => read_system,
      :show => read_system,
      :facts => read_system,
      :bulk_destroy => delete_systems
    }
  end

  def new
  end

  def create
  end

  def index
  end

  def items
  end

  def packages
    offset = current_user.page_size
    packages = @system.simple_packages.sort {|a,b| a.nvrea.downcase <=> b.nvrea.downcase}
    if packages.length > 0
      if params.has_key? :pkg_order
        if params[:pkg_order].downcase == "desc"
          packages.reverse!
        end
      end
      packages = packages[0...offset]
    else
      packages = []
    end
    render :partial=>"packages", :layout => "tupane_layout", :locals=>{:system=>@system, :packages => packages,
                                                                       :offset => offset, :editable => @system.editable?}
  end

  def more_packages
    #grab the current user setting for page size
    size = current_user.page_size
    #what packages are available?
    packages = @system.simple_packages.sort {|a,b| a.nvrea.downcase <=> b.nvrea.downcase}
    if packages.length > 0
      #check for the params offset (start of array chunk)
      if params.has_key? :offset
        offset = params[:offset].to_i
      else
        offset = current_user.page_size
      end
      if params.has_key? :pkg_order
        if params[:pkg_order].downcase == "desc"
          #reverse if order is desc
          packages.reverse!
        end
      end
      if params.has_key? :reverse
        packages = packages[0...params[:reverse].to_i]
      else
        packages = packages[offset...offset+size]
      end
    else
      packages = []
    end
    render :partial=>"more_packages", :locals=>{:system=>@system, :packages => packages, :offset=> offset}
  end

  def edit
  end

  def update
  end

  def show
  end

  def section_id
    'systems'
  end

  private

  include SortColumnList

  def find_system
    @system = System.find(params[:system_id])
  end

  def controller_display_name
    return _('system')
  end

  def sort_order_limit systems
      sort_columns(COLUMNS, systems) if params[:order]
      offset = params[:offset].to_i if params[:offset]
      offset ||= 0
      last = offset + current_user.page_size
      last = systems.length if last > systems.length
      systems[offset...last]
  end

end
