import 'package:flutter_test/flutter_test.dart';

import 'package:glances_client_advanced/data/models/alert_info.dart';
import 'package:glances_client_advanced/data/models/cpu_info.dart';
import 'package:glances_client_advanced/data/models/docker_container_info.dart';
import 'package:glances_client_advanced/data/models/folders_info.dart';
import 'package:glances_client_advanced/data/models/fs_info.dart';
import 'package:glances_client_advanced/data/models/glances_all.dart';
import 'package:glances_client_advanced/data/models/gpu_info.dart';
import 'package:glances_client_advanced/data/models/ip_info.dart';
import 'package:glances_client_advanced/data/models/port_info.dart';
import 'package:glances_client_advanced/data/models/process_count_info.dart';
import 'package:glances_client_advanced/data/models/process_info.dart';
import 'package:glances_client_advanced/data/models/program_info.dart';
import 'package:glances_client_advanced/data/models/sensor_info.dart';
import 'package:glances_client_advanced/data/models/system_info.dart';
import 'package:glances_client_advanced/data/models/vm_info.dart';
import 'package:glances_client_advanced/data/models/wifi_info.dart';

void main() {
  group('DockerContainerInfo.fromJson', () {
    test('parses command as a String for active containers', () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{
          'name': 'grafana',
          'id': 'abc123',
          'status': 'healthy',
          'command': '/run.sh',
        },
      );
      expect(info.command, '/run.sh');
    });

    test('normalizes command list from inactive containers to a String', () {
      // Glances returns the raw argv list when a container is unhealthy or
      // stopped (the Docker engine only joins the command on the active path).
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{
          'name': 'loki',
          'id': '704753e8bdfe',
          'status': 'unhealthy',
          'command': <String>[
            '/usr/bin/loki',
            '-config.file=/etc/loki/loki-config.yml',
          ],
        },
      );
      expect(info.command, '/usr/bin/loki -config.file=/etc/loki/loki-config.yml');
    });

    test('tolerates a null command', () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{'name': 'x', 'status': 'exited'},
      );
      expect(info.command, isNull);
    });

    test('normalizes image List and String forms', () {
      final DockerContainerInfo list = DockerContainerInfo.fromJson(
        <String, dynamic>{'image': <String>['grafana/loki:latest']},
      );
      expect(list.image, <String>['grafana/loki:latest']);

      final DockerContainerInfo single = DockerContainerInfo.fromJson(
        <String, dynamic>{'image': 'nginx:latest'},
      );
      expect(single.image, <String>['nginx:latest']);
    });

    test('unhealthy containers are still "running" per isRunning', () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{'status': 'unhealthy'},
      );
      expect(info.isRunning, isTrue);
    });

    test('parses memory_percent (Glances 4.5.x container key)', () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{'memory_percent': 12.5},
      );
      expect(info.memPercent, 12.5);
    });

    test('parses legacy mem_percent key', () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{'mem_percent': 25.0},
      );
      expect(info.memPercent, 25.0);
    });

    test('memoryPercent falls back to memory usage/limit when memPercent is null',
        () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{
          'memory': <String, dynamic>{'usage': 512.0, 'limit': 1024.0},
        },
      );
      expect(info.memPercent, isNull);
      expect(info.memoryPercent, 50.0);
    });

    test('memoryPercent prefers the parsed percentage over the byte ratio',
        () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{
          'memory_percent': 30.0,
          'memory': <String, dynamic>{'usage': 512.0, 'limit': 1024.0},
        },
      );
      expect(info.memoryPercent, 30.0);
    });

    test('memoryPercent returns null when the limit is missing', () {
      final DockerContainerInfo info = DockerContainerInfo.fromJson(
        <String, dynamic>{
          'memory': <String, dynamic>{'usage': 512.0},
        },
      );
      expect(info.memoryPercent, isNull);
    });
  });

  group('ProcessInfo.fromJson', () {
    test('parses memory_percent (Glances 4.5.x processlist key)', () {
      final ProcessInfo info = ProcessInfo.fromJson(<String, dynamic>{
        'pid': 42,
        'name': 'nginx',
        'memory_percent': 3.5,
      });
      expect(info.memPercent, 3.5);
    });

    test('falls back to legacy mem_percent key', () {
      final ProcessInfo info = ProcessInfo.fromJson(<String, dynamic>{
        'pid': 42,
        'name': 'nginx',
        'mem_percent': 2.5,
      });
      expect(info.memPercent, 2.5);
    });

    test('prefers memory_percent over mem_percent when both present', () {
      final ProcessInfo info = ProcessInfo.fromJson(<String, dynamic>{
        'memory_percent': 4.0,
        'mem_percent': 1.0,
      });
      expect(info.memPercent, 4.0);
    });

    test('returns null when neither memory key is present', () {
      final ProcessInfo info = ProcessInfo.fromJson(<String, dynamic>{
        'pid': 42,
        'name': 'nginx',
      });
      expect(info.memPercent, isNull);
    });
  });

  group('FsInfo.fromJson', () {
    test('parses the Glances 4.5.6 fs plugin payload including options and free',
        () {
      final FsInfo info = FsInfo.fromJson(<String, dynamic>{
        'device_name': '/dev/sda1',
        'fs_type': 'ext4',
        'mnt_point': '/',
        'options': 'rw,relatime',
        'size': 1000000,
        'used': 400000,
        'free': 600000,
        'percent': 40.0,
      });
      expect(info.deviceName, '/dev/sda1');
      expect(info.fsType, 'ext4');
      expect(info.mntPoint, '/');
      expect(info.options, 'rw,relatime');
      expect(info.size, 1000000);
      expect(info.used, 400000);
      expect(info.free, 600000);
      expect(info.percent, 40.0);
    });

    test('tolerates missing options and free', () {
      final FsInfo info = FsInfo.fromJson(<String, dynamic>{
        'device_name': '/dev/sda1',
        'size': 1000000,
      });
      expect(info.options, isNull);
      expect(info.free, isNull);
    });
  });

  group('CpuInfo.fromJson', () {
    test('parses the remaining verified breakdown fields', () {
      final CpuInfo info = CpuInfo.fromJson(<String, dynamic>{
        'idle': 45.2,
        'ctx_switches': 12345,
        'syscalls': 67890,
        'guest': 1.5,
        'guest_nice': 0.5,
      });
      expect(info.idle, 45.2);
      expect(info.ctxSwitches, 12345);
      expect(info.syscalls, 67890);
      expect(info.guest, 1.5);
      expect(info.guestNice, 0.5);
    });

    test('tolerates missing breakdown fields', () {
      final CpuInfo info = CpuInfo.fromJson(<String, dynamic>{'total': 25.9});
      expect(info.idle, isNull);
      expect(info.ctxSwitches, isNull);
      expect(info.syscalls, isNull);
      expect(info.guest, isNull);
      expect(info.guestNice, isNull);
    });
  });

  group('GlancesAll.fromJson', () {
    test('parses a full /api/4/all payload including a list-command container',
        () {
      final GlancesAll all = GlancesAll.fromJson(<String, dynamic>{
        'cpu': <String, dynamic>{'total': 25.9, 'cpucore': 3},
        'mem': <String, dynamic>{'total': 100, 'used': 40, 'percent': 40.0},
        'load': <String, dynamic>{'min1': 1.0, 'min5': 0.8, 'min15': 0.6, 'cpucore': 3},
        'processcount': <String, dynamic>{
          'total': 315,
          'running': 0,
          'sleeping': 173,
          'thread': 1326,
        },
        'containers': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'grafana',
            'id': 'a1',
            'status': 'healthy',
            'command': '/run.sh',
          },
          <String, dynamic>{
            'name': 'loki',
            'id': 'b2',
            'status': 'unhealthy',
            'command': <String>['/usr/bin/loki', '-config.file=/etc/loki/loki-config.yml'],
            'image': <String>['grafana/loki:latest'],
          },
        ],
      });

      expect(all.cpu?.total, 25.9);
      expect(all.docker, hasLength(2));
      expect(all.docker![0].command, '/run.sh');
      expect(
        all.docker![1].command,
        '/usr/bin/loki -config.file=/etc/loki/loki-config.yml',
      );
      expect(all.docker![1].image, <String>['grafana/loki:latest']);
    });
  });

  group('SensorInfo.fromJson', () {
    test('parses a temperature_core item with thresholds', () {
      final SensorInfo info = SensorInfo.fromJson(<String, dynamic>{
        'type': 'temperature_core',
        'label': 'Core 0',
        'key': 'label',
        'value': 42.0,
        'unit': 'C',
        'warning': 80.0,
        'critical': 90.0,
      });
      expect(info.type, 'temperature_core');
      expect(info.label, 'Core 0');
      expect(info.key, 'label');
      expect(info.value, 42.0);
      expect(info.valueAsDouble, 42.0);
      expect(info.unit, 'C');
      expect(info.warning, 80.0);
      expect(info.critical, 90.0);
      expect(info.level, 0);
    });

    test('parses an HDD error item with a String value', () {
      // hddtemp reports error states as strings, never as numbers.
      final SensorInfo info = SensorInfo.fromJson(<String, dynamic>{
        'type': 'temperature_hdd',
        'label': 'sda',
        'value': 'ERR',
        'unit': 'C',
      });
      expect(info.value, 'ERR');
      expect(info.valueAsDouble, isNull);
      expect(info.level, 0);
    });

    test('parses a battery item with status and no thresholds', () {
      final SensorInfo info = SensorInfo.fromJson(<String, dynamic>{
        'type': 'battery',
        'label': 'BAT BAT0',
        'value': 87.0,
        'unit': '%',
        'status': 'Discharging',
      });
      expect(info.type, 'battery');
      expect(info.status, 'Discharging');
      expect(info.warning, isNull);
      expect(info.critical, isNull);
      expect(info.level, 0);
    });
  });

  group('SystemInfo.fromJson', () {
    test('parses the real /api/4/system payload', () {
      final SystemInfo info = SystemInfo.fromJson(<String, dynamic>{
        'os_name': 'Linux',
        'hostname': 'glances',
        'platform': '64bit',
        'os_version': '6.18.33.2-microsoft-standard-WSL2',
        'linux_distro': 'Ubuntu 26.04',
        'hr_name': 'Ubuntu 26.04 64bit / Linux 6.18.33.2-microsoft-standard-WSL2',
      });
      expect(info.osName, 'Linux');
      expect(info.hostname, 'glances');
      expect(info.platform, '64bit');
      expect(info.osVersion, '6.18.33.2-microsoft-standard-WSL2');
      expect(info.linuxDistro, 'Ubuntu 26.04');
      expect(
        info.hrName,
        'Ubuntu 26.04 64bit / Linux 6.18.33.2-microsoft-standard-WSL2',
      );
    });
  });

  group('AlertInfo.fromJson', () {
    test('parses an ongoing LOAD warning with global_msg', () {
      final AlertInfo info = AlertInfo.fromJson(<String, dynamic>{
        'begin': 1751400000,
        'end': -1,
        'state': 'WARNING',
        'type': 'LOAD',
        'min': 1.0,
        'max': 1.5,
        'sum': 13.1,
        'count': 10,
        'avg': 1.31,
        'top': <String>['dockerd', 'containerd'],
        'desc': 'desc',
        'sort': 'min1',
        'global_msg': 'System overloaded in the last 5 minutes',
      });
      expect(info.globalMsg, 'System overloaded in the last 5 minutes');
      expect(info.state, 'WARNING');
      expect(info.type, 'LOAD');
      expect(info.min, 1.0);
      expect(info.max, 1.5);
      expect(info.sum, 13.1);
      expect(info.count, 10);
      expect(info.avg, 1.31);
      expect(info.top, <String>['dockerd', 'containerd']);
      expect(info.isOngoing, isTrue);
      expect(info.isCritical, isFalse);
    });

    test('parses a closed CRITICAL alert', () {
      final AlertInfo info = AlertInfo.fromJson(<String, dynamic>{
        'state': 'CRITICAL',
        'type': 'CPU',
        'end': 1751403600,
      });
      expect(info.isCritical, isTrue);
      expect(info.isOngoing, isFalse);
    });
  });

  group('ProcessCountInfo.fromJson', () {
    test('parses thread and pid_max keys', () {
      final ProcessCountInfo info = ProcessCountInfo.fromJson(
        <String, dynamic>{
          'total': 409,
          'running': 0,
          'sleeping': 171,
          'thread': 1468,
          'pid_max': 0,
        },
      );
      expect(info.total, 409);
      expect(info.running, 0);
      expect(info.sleeping, 171);
      expect(info.threads, 1468);
      expect(info.pidMax, 0);
    });
  });

  group('IpInfo.fromJson', () {
    test('parses the real /api/4/ip payload', () {
      final IpInfo info = IpInfo.fromJson(<String, dynamic>{
        'address': '172.16.210.137',
        'mask': '255.255.240.0',
        'mask_cidr': 20,
        'gateway': '172.16.210.1',
        'public_address': '84.23.10.5',
        'public_info_human': 'FR / Europe',
      });
      expect(info.address, '172.16.210.137');
      expect(info.mask, '255.255.240.0');
      expect(info.maskCidr, 20);
      expect(info.gateway, '172.16.210.1');
      expect(info.publicAddress, '84.23.10.5');
      expect(info.publicInfoHuman, 'FR / Europe');
    });

    test('tolerates missing public fields', () {
      final IpInfo info = IpInfo.fromJson(<String, dynamic>{
        'address': '192.168.1.10',
      });
      expect(info.address, '192.168.1.10');
      expect(info.maskCidr, isNull);
      expect(info.publicAddress, isNull);
      expect(info.publicInfoHuman, isNull);
    });
  });

  group('WifiInfo.fromJson', () {
    test('parses a wifi plugin item', () {
      final WifiInfo info = WifiInfo.fromJson(<String, dynamic>{
        'ssid': 'HomeNet',
        'quality_link': 70,
        'quality_level': -41,
      });
      expect(info.ssid, 'HomeNet');
      expect(info.qualityLink, 70);
      expect(info.qualityLevel, -41);
    });

    test('tolerates missing quality keys', () {
      final WifiInfo info = WifiInfo.fromJson(<String, dynamic>{});
      expect(info.ssid, isNull);
      expect(info.qualityLink, isNull);
      expect(info.qualityLevel, isNull);
    });
  });

  group('PortInfo.fromJson', () {
    test('parses a reachable port measurement', () {
      final PortInfo info = PortInfo.fromJson(<String, dynamic>{
        'host': 'example.com',
        'port': 443,
        'description': 'HTTPS',
        'refresh': 5,
        'timeout': 3,
        'status': 0.025,
        'rtt_warning': 1.0,
        'indice': 0,
      });
      expect(info.host, 'example.com');
      expect(info.port, 443);
      expect(info.description, 'HTTPS');
      expect(info.status, 0.025);
      expect(info.rttWarning, 1.0);
      expect(info.indice, 0);
      expect(info.isReachable, isTrue);
      expect(info.rttMs, closeTo(25.0, 0.001));
    });

    test('treats a null status as unreachable', () {
      final PortInfo info = PortInfo.fromJson(<String, dynamic>{
        'host': 'down.host',
        'port': 80,
      });
      expect(info.isReachable, isFalse);
      expect(info.rttMs, isNull);
    });
  });

  group('VmInfo.fromJson', () {
    test('parses a running virsh VM', () {
      final VmInfo info = VmInfo.fromJson(<String, dynamic>{
        'name': 'ubuntu',
        'id': '2',
        'release': 'Ubuntu 26.04',
        'status': 'running',
        'cpu_count': 4,
        'cpu_time': 12.5,
        'memory_usage': 1048576,
        'memory_total': 4194304,
        'load_1min': 0.5,
        'load_5min': 0.4,
        'load_15min': 0.3,
        'ipv4': '10.0.0.5',
        'engine': 'virsh',
        'engine_version': '9.0.0',
      });
      expect(info.name, 'ubuntu');
      expect(info.id, '2');
      expect(info.status, 'running');
      expect(info.cpuCount, 4);
      expect(info.cpuTime, 12.5);
      expect(info.memoryUsage, 1048576);
      expect(info.memoryTotal, 4194304);
      expect(info.load1min, 0.5);
      expect(info.load5min, 0.4);
      expect(info.load15min, 0.3);
      expect(info.ipv4, '10.0.0.5');
      expect(info.engine, 'virsh');
      expect(info.engineVersion, '9.0.0');
    });

    test('tolerates missing optional keys (multipass engine)', () {
      final VmInfo info = VmInfo.fromJson(<String, dynamic>{
        'name': 'primary',
        'status': 'running',
      });
      expect(info.name, 'primary');
      expect(info.cpuTime, isNull);
      expect(info.memoryUsage, isNull);
      expect(info.load1min, isNull);
      expect(info.engineVersion, isNull);
    });
  });

  group('FolderInfo.fromJson', () {
    test('parses a full folder entry', () {
      final FolderInfo info = FolderInfo.fromJson(<String, dynamic>{
        'name': 'custom-folders',
        'used': 1073741824,
        'free': 300006731776,
        'size': 301081395200,
        'percent': 0.35,
      });
      expect(info.name, 'custom-folders');
      expect(info.used, 1073741824);
      expect(info.free, 300006731776);
      expect(info.size, 301081395200);
      expect(info.percent, 0.35);
    });

    test('tolerates missing optional keys', () {
      final FolderInfo info = FolderInfo.fromJson(<String, dynamic>{
        'name': 'minimal',
      });
      expect(info.name, 'minimal');
      expect(info.used, isNull);
      expect(info.free, isNull);
      expect(info.size, isNull);
      expect(info.percent, isNull);
    });
  });

  group('GpuInfo.fromJson', () {
    test('parses a full GPU entry', () {
      final GpuInfo info = GpuInfo.fromJson(<String, dynamic>{
        'key': 'AMD_0',
        'name': 'AMD RX 6900 XT',
        'vendor': 'amd',
        'driver': 'amdgpu',
        'temperature': 51.0,
        'mem': 30,
        'proc': 12,
      });
      expect(info.key, 'AMD_0');
      expect(info.name, 'AMD RX 6900 XT');
      expect(info.vendor, 'amd');
      expect(info.driver, 'amdgpu');
      expect(info.temperature, 51.0);
      expect(info.mem, 30);
      expect(info.proc, 12);
    });

    test('tolerates missing optional keys', () {
      final GpuInfo info = GpuInfo.fromJson(<String, dynamic>{
        'name': 'Mali-G77',
      });
      expect(info.name, 'Mali-G77');
      expect(info.vendor, isNull);
      expect(info.temperature, isNull);
      expect(info.mem, isNull);
      expect(info.proc, isNull);
    });
  });

  group('ProgramInfo.fromJson', () {
    test('parses an aggregated program entry', () {
      final ProgramInfo info = ProgramInfo.fromJson(<String, dynamic>{
        'name': 'glances',
        'cmdline': <String>['python', '/usr/bin/glances'],
        'pid': '_',
        'cpu_percent': 3.4,
        'memory_percent': 1.5,
        'num_threads': 5,
        'nprocs': 2,
        'username': 'pi',
        'status': 'S',
      });
      expect(info.name, 'glances');
      expect(info.cmdline, <String>['python', '/usr/bin/glances']);
      expect(info.pid, '_');
      expect(info.cpuPercent, 3.4);
      expect(info.memoryPercent, 1.5);
      expect(info.numThreads, 5);
      expect(info.nprocs, 2);
      expect(info.username, 'pi');
      expect(info.status, 'S');
    });

    test('tolerates missing optional keys', () {
      final ProgramInfo info = ProgramInfo.fromJson(<String, dynamic>{
        'name': 'sleep',
      });
      expect(info.name, 'sleep');
      expect(info.cpuPercent, isNull);
      expect(info.memoryPercent, isNull);
      expect(info.numThreads, isNull);
      expect(info.nprocs, isNull);
    });
  });
}
