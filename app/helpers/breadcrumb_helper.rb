#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module BreadcrumbHelper
  def full_breadcrumb
    if show_defaults
      breadcrumb_list(link_to(icon_wrapper('icon2 icon-home', I18n.t(:label_home)), home_path),
                      link_to_project_ancestors(@project),
                      *breadcrumb_paths)
    else
      breadcrumb_list(*breadcrumb_paths)
    end
  end

  def breadcrumb(*args)
    elements = args.flatten
    elements.any? ? content_tag('p', (args.join(' &#187; ') + ' &#187; ').html_safe, class: 'op-breadcrumb') : nil
  end

  def breadcrumb_list(*args)
    elements = args.flatten
    breadcrumb_elements = [content_tag(:li,
                                       elements.shift.to_s,
                                       class: 'first-breadcrumb-element',
                                       style: 'list-style-image:none;')]

    breadcrumb_elements += elements.map do |element|
      if element
        css_class = if element.try(:include?, 'op-breadcrumb-project-title')
                      'op-breadcrumb-project-element '
                    end
        content_tag(:li,
                    h(element.to_s),
                    class: "#{css_class} icon4 icon-small icon-arrow-right5")
      end
    end

    content_tag(:ul, breadcrumb_elements.join.html_safe, class: 'op-breadcrumb',  'data-qa-selector': 'op-breadcrumb')
  end

  def breadcrumb_paths(*args)
    if args.nil?
      nil
    elsif args.empty?
      @breadcrumb_paths ||= [default_breadcrumb]
    else
      @breadcrumb_paths ||= []
      @breadcrumb_paths += args
    end
  end

  def show_breadcrumb
    if !!(defined? show_local_breadcrumb)
      show_local_breadcrumb
    else
      false
    end
  end

  def show_defaults
    if !!(defined? show_local_breadcrumb_defaults)
      show_local_breadcrumb_defaults
    else
      false
    end
  end

  private

  def link_to_project_ancestors(project)
    if project && !project.new_record?
      ancestors = (project.root? ? [] : project.ancestors.visible.to_a)
      ancestors << project
      ancestors.map do |p|
        if p == project
          link_to_project(p, { only_path: false }, title: p, class: 'op-breadcrumb-project-title nocut').html_safe
        else
          link_to_project(p, { jump: current_menu_item }, title: p, class: 'op-breadcrumb-project-title').html_safe
        end
      end
    end
  end
end
