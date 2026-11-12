require 'rails_helper'

# fe has no JS test runner, so this loads the real fe.public.nojquery script in Node
# with a stand-in jQuery and checks what loadPage does to the page being left.
describe 'fe.pageHandler.loadPage' do
  let(:script) do
    ERB.new(File.read(Fe::Engine.root.join('app/assets/javascripts/fe/fe.public.nojquery.js.erb'))).result(binding)
  end

  def run_load_page(background_load)
    harness = <<~JS
      const vm = require('vm');
      const elements = {};
      const element = (selector) => {
        if (elements[selector]) return elements[selector];
        const data = {};
        const target = { length: 0, data: (key, value) => (value === undefined ? data[key] : (data[key] = value, proxy)) };
        const proxy = new Proxy(target, { get: (t, key) => (key in t ? t[key] : () => proxy) });
        return (elements[selector] = proxy);
      };
      const chain = new Proxy(function() {}, { get: () => chain, apply: () => chain, set: () => true });
      const $ = (arg) => (typeof arg === 'string' ? element(arg) : chain);
      Object.assign($, { validator: chain, ajax: () => {}, _data: () => ({}) });
      const cleared = [];
      const ctx = { $, jQuery: $, document: { addEventListener() {} }, console, clearInterval: (id) => cleared.push(id), setInterval: () => 99 };
      ctx.window = ctx;
      vm.runInNewContext(#{script.to_json}, ctx);
      const handler = ctx.fe.pageHandler;
      let saves = 0;
      Object.assign(handler, {
        current_page: 'page_a', timer_id: 42,
        savePage: () => { saves += 1; }, validatePage: () => true, isPageLoaded: () => true, showPage: () => {},
      });
      handler.loadPage('page_b', '/page_b/edit', #{background_load});
      console.log(JSON.stringify({ timerCleared: cleared.includes(42), saves, savedOnLeave: element('#page_a').data('saved_on_leave') || false }));
    JS
    JSON.parse(IO.popen(['node', '-e', harness], &:read))
  end

  before { skip 'node is not installed' unless system('node', '-v', out: File::NULL, err: File::NULL) }

  it 'leaves autosave running and the page unmarked when a conditional loads another page in the background' do
    expect(run_load_page(true)).to eq('timerCleared' => false, 'saves' => 0, 'savedOnLeave' => false)
  end

  it 'stops autosave and saves the page once when the user moves to another page' do
    expect(run_load_page(false)).to eq('timerCleared' => true, 'saves' => 1, 'savedOnLeave' => true)
  end
end
