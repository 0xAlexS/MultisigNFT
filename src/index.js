/**
 * File: index.js
 * Desc: This is the main entry-point for the web application
 */

import {ethers} from 'ethers';

let _provider;
let _signer;

(async () => {
  if (window.ethereum == null) {
    console.log("metamask is not installed");
    _provider = ethers.getDefaultProvider();
  } else {
    _provider = new ethers.BrowserProvider(window.ethereum);
    _signer = await _provider.getSigner();
    console.log("MM connected!");
  }
})();