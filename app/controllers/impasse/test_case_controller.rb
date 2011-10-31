module Impasse
  class TestCaseController < AbstractController
    unloadable

    REL = {1=>"test_project", 2=>"test_suite", 3=>"test_case"}

    menu_item :impasse
    before_filter :find_project, :authorize

    def index
      @nodes = Node.find(:all, :conditions => ["name=? and node_type_id=?", @project.name, 1])
    end

    def list
      @nodes = Node.find_children(params[:node_id], params[:test_plan_id])
      jstree_nodes = convert(@nodes, params[:prefix])

      respond_to do |format|
        format.json { render :json => jstree_nodes }
      end
    end

    def new
      @node = Node.new(params[:node])

      case params[:node_type]
      when 'test_case'
        @test_case = TestCase.new(params[:test_case])
        @node.node_type_id = 3
      else
        @test_case = TestSuite.new(params[:test_case])
        @node.node_type_id = 2
      end
    
      if request.post? and @node.save
        @test_case.id = @node.id
        if @node.is_test_case? and params.include? :test_steps
          test_steps = params[:test_steps].collect{|i, ts| TestStep.new(ts) }
          @test_case.test_steps.replace(test_steps)
        end
        @test_case.save!

        respond_to do |format|
          format.json { render :json => @test_case }
        end
      else
        render :partial => 'new'
      end
    end

    def edit
      @node = Node.find(params[:node][:id])
      old_node = @node.clone

      case params[:node_type]
      when 'test_case'
        @test_case = TestCase.find(params[:node][:id])
      else
        @test_case = TestSuite.find(params[:node][:id])
      end

      if request.post?
        @node.attributes = params[:node]
        @node.save!
        @node.update_siblings_order!(old_node)
        # If node has children, must update the node path of child nodes.
        @node.update_child_nodes_path(old_node.path)


        @test_case.attributes = params[:test_case]
        @test_case.save!
        if @node.is_test_case? and params.include? :test_steps
          test_steps = params[:test_steps].collect{|i, ts| TestStep.new(ts) }
          @test_case.test_steps.replace(test_steps)
        end

        respond_to do |format|
          format.json { render :json => @test_case }
        end
      else
        render :partial => 'edit'
      end
    end

    def destroy
      @node = Node.find(params[:node][:id])
      case @node.node_type_id
      when 2
        TestSuite.delete(@node.id)
      end

      @node.delete
      
      respond_to do |format|
        format.json { render :json => params[:node][:id] }
      end
    end

    private
    def find_project
      begin
        @project = Project.find(params[:project_id])
        @project_node = Node.find(:first, :conditions=>["name=? and node_type_id=?", @project.name, 1])
        if @project_node.nil?
          @project_node = Node.new(:name=>@project.name, :node_type_id=>1, :node_order=>1)
          @project_node.save
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end
    end

    private
    def convert(nodes, prefix='node')
      node_map = {}
      jstree_nodes = []
    
      for node in nodes
        jstree_node = {
          'attr' => {'id' => "#{prefix}_#{node.id}" , 'rel' => REL[node.node_type_id]},
          'data' => { 'title' => node.name },
          'children'=>[]}
        if node.node_type_id != 3
          jstree_node['state'] = 'open'
        end

        node_map[node.id] = jstree_node
        if node_map.include? node.parent_id
          # non-root node
          node_map[node.parent_id]['children'] << jstree_node
        else
          #root node
          jstree_nodes << jstree_node
        end
      end
      jstree_nodes
    end
  end
end
