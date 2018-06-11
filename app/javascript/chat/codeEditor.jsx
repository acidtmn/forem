import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import setupPusher from '../src/utils/pusher';

export default class CodeEditor extends Component {

  componentDidMount() {
    const editor = document.getElementById("codeeditor");
    const channel = setupPusher(this.props.pusherKey, {
      channelId: `presence-channel-${this.props.activeChannelId}`,
      liveCoding: this.liveCoding,
    });
    const myCodeMirror = CodeMirror(editor, {
      mode:  "javascript",
      theme: "material",
      autofocus: true,
    });
    myCodeMirror.setSize("100%", "100%");
    //Initial trigger:
    channel.trigger('client-livecode', {
      value: myCodeMirror.getValue(),
      cursorPos: myCodeMirror.getCursor(),
    });
    //Coding trigger:
    myCodeMirror.on('keyup', cm => {
        channel.trigger('client-livecode', {
          keyPressed: true,
          value: cm.getValue(),
          cursorPos: cm.getCursor(),
        });
    });
  }

  shouldComponentUpdate() {
    return false;
  }
  
  liveCoding = e => {
    console.log("live coding")
    if (e.keyPressed === true || e.value.length > 0) {
      let cm = document.querySelector(".CodeMirror").CodeMirror
      const cursorCoords = e.cursorPos
      const cursorElement = document.createElement('span');
      cursorElement.classList.add("cursorelement")
      cursorElement.style.height = `${(cursorCoords.bottom - cursorCoords.top)}px`;
      cm.setValue(e.value);
      cm.setBookmark(e.cursorPos, { widget: cursorElement });
    } else {
      let cm = document.querySelector(".CodeMirror").CodeMirror
      console.log("NEW LIVE CODING")
      channel.trigger('client-livecode', {
        value: cm.getValue(),
        cursorPos: cm.getCursor(),
      });
    }
  }

  render() {

    return <div id="codeeditor" className="chatcodeeditor"></div>

  }

}