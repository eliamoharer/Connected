# Connected

![Platform](https://img.shields.io/badge/Platform-iOS%2026%2B%20%7C%20iPadOS%2026%2B-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
<img width="4000" height="4000" alt="image" src="https://github.com/user-attachments/assets/45562366-519b-4905-a68a-fdf74ab783d3" />

An iOS application that lets you easily access and chat with locally hosted models over an internet connection.

Endpoints are automatically scanned over your local network. For long distance, there are VPNs such as Tailscale which can act as a local connection between your devices.

Only endpoints in the style of /v1/chat/completions are supported.

## Features

* Features include fully customizable profiles, allowing you to tweak hyperparameters and toggle thinking. The app also allows you to set a system prompt. 
* Image uploading is functional and resizes images to a max of 512px longest edge. Some models may not support vision capabilities, resulting in the LLM ignoring image uploads.

## How to Use

To use, simply download the project, and open the .xcodeproj in Xcode.

## Compatibility & License

Connected is supported on iOS 26+ and iPadOS 26+, with unconfirmed support on Mac.

This project uses SwiftStreamingMarkdown by Microsoft. Thank you!
