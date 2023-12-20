/*
 * This file is part of demospringboot.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * Copyright (C) hdsdi3g for hd3g.tv 2023
 *
 */
package tv.hd3g.democlispringboot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.CommandLineRunner;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;

@SpringBootApplication
@EnableAutoConfiguration
@Slf4j
public class DemoApp implements CommandLineRunner {

	private int exitCode;

	public static void main(final String[] args) {
		SpringApplication.exit(SpringApplication.run(DemoApp.class, args));
	}

	@Override
	public void run(final String... args) throws Exception {
		System.out.println(args[0]);
		System.out.println(args[1]);
	}

}
