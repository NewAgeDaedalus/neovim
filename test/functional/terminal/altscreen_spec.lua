local helpers = require('test.functional.helpers')(after_each)
local thelpers = require('test.functional.terminal.helpers')
local clear, eq, curbuf = helpers.clear, helpers.eq, helpers.curbuf
local feed = helpers.feed
local feed_data = thelpers.feed_data
local enter_altscreen = thelpers.enter_altscreen
local exit_altscreen = thelpers.exit_altscreen

if helpers.skip(helpers.is_os('win')) then
  return
end

describe(':terminal altscreen', function()
  local screen

  before_each(function()
    clear()
    screen = thelpers.screen_setup()
    feed_data({
      'line1',
      'line2',
      'line3',
      'line4',
      'line5',
      'line6',
      'line7',
      'line8',
      '',
    })
    screen:expect([[
      line4                                             |
      line5                                             |
      line6                                             |
      line7                                             |
      line8                                             |
      {1: }                                                 |
      {3:-- TERMINAL --}                                    |
    ]])
    enter_altscreen()
    screen:expect([[
                                                        |*5
      {1: }                                                 |
      {3:-- TERMINAL --}                                    |
    ]])
    eq(10, curbuf('line_count'))
  end)

  it('wont clear lines already in the scrollback', function()
    feed('<c-\\><c-n>gg')
    screen:expect([[
      ^tty ready                                         |
      line1                                             |
      line2                                             |
      line3                                             |
                                                        |*3
    ]])
  end)

  describe('on exit', function()
    before_each(exit_altscreen)

    it('restores buffer state', function()
      screen:expect([[
        line4                                             |
        line5                                             |
        line6                                             |
        line7                                             |
        line8                                             |
        {1: }                                                 |
        {3:-- TERMINAL --}                                    |
      ]])
      feed('<c-\\><c-n>gg')
      screen:expect([[
        ^tty ready                                         |
        line1                                             |
        line2                                             |
        line3                                             |
        line4                                             |
        line5                                             |
                                                          |
      ]])
    end)
  end)

  describe('with lines printed after the screen height limit', function()
    before_each(function()
      feed_data({
        'line9',
        'line10',
        'line11',
        'line12',
        'line13',
        'line14',
        'line15',
        'line16',
        '',
      })
      screen:expect([[
        line12                                            |
        line13                                            |
        line14                                            |
        line15                                            |
        line16                                            |
        {1: }                                                 |
        {3:-- TERMINAL --}                                    |
      ]])
    end)

    it('wont modify line count', function()
      eq(10, curbuf('line_count'))
    end)

    it('wont modify lines in the scrollback', function()
      feed('<c-\\><c-n>gg')
      screen:expect([[
        ^tty ready                                         |
        line1                                             |
        line2                                             |
        line3                                             |
        line12                                            |
        line13                                            |
                                                          |
      ]])
    end)
  end)

  describe('after height is decreased by 2', function()
    local function wait_removal()
      screen:try_resize(screen._width, screen._height - 2)
      screen:expect([[
                                                          |*2
        rows: 4, cols: 50                                 |
        {1: }                                                 |
        {3:-- TERMINAL --}                                    |
      ]])
    end

    it('removes 2 lines from the bottom of the visible buffer', function()
      wait_removal()
      feed('<c-\\><c-n>4k')
      screen:expect([[
        ^                                                  |
                                                          |*2
        rows: 4, cols: 50                                 |
                                                          |
      ]])
      eq(9, curbuf('line_count'))
    end)

    describe('and after exit', function()
      before_each(function()
        wait_removal()
        exit_altscreen()
      end)

      it('restore buffer state', function()
        screen:expect([[
          line5                                             |
          line6                                             |
          line7                                             |
          line8                                             |
          {3:-- TERMINAL --}                                    |
        ]])
      end)
    end)
  end)
end)
