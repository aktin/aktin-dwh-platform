package org.example.app;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** Example endpoint. Replace with your own code. */
@RestController
public class HelloController {

  @GetMapping("/hello")
  public String hello() {
    return "Hello, world!";
  }
}
