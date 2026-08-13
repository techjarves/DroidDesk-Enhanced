package com.orailnoor.droiddesk.runtime

import android.content.Context
import android.util.Log
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/** Shared desktop conveniences that are independent of the active Linux mode. */
class DesktopIntegration(private val context: Context) {
    companion object {
        private const val TAG = "DesktopIntegration"
    }

    private val snapshotsDir = File(context.filesDir, "snapshots").apply { mkdirs() }

    fun search(query: String, rooted: Boolean, limit: Int = 80): List<Map<String, String>> {
        val needle = query.trim().lowercase()
        val results = mutableListOf<Map<String, String>>()
        AndroidAppBridge.listApps(context).forEach { app ->
            if (needle.isEmpty() || app.values.any { it.lowercase().contains(needle) }) {
                results += app + mapOf("kind" to "android", "id" to app.getValue("package"))
            }
        }

        val home = linuxHome(rooted)
        val appDirs = if (rooted) {
            listOf(File(context.filesDir, "rootfs/usr/share/applications"), File(home, ".local/share/applications"))
        } else {
            listOf(File(context.filesDir, "usr/share/applications"), File(home, ".local/share/applications"))
        }
        appDirs.filter(File::isDirectory).flatMap { directory ->
            directory.walkTopDown().maxDepth(2).filter { it.isFile && it.extension == "desktop" }.toList()
        }.filterNot { desktopFile ->
            desktopFile.parentFile?.name in setOf("droiddesk-android", "droiddesk-tools")
        }.distinctBy { it.name }.forEach { desktopFile ->
            val fields = desktopFields(desktopFile)
            if (fields["NoDisplay"].equals("true", ignoreCase = true)) return@forEach
            val name = fields["Name"] ?: return@forEach
            val haystack = "$name ${fields["Comment"].orEmpty()} ${fields["Keywords"].orEmpty()}".lowercase()
            if (needle.isEmpty() || haystack.contains(needle)) {
                results += mapOf(
                    "label" to name,
                    "subtitle" to fields["Comment"].orEmpty(),
                    "source" to "Linux",
                    "kind" to "linux",
                    "id" to desktopFile.nameWithoutExtension,
                )
            }
        }

        val shortcuts = listOf(
            mapOf("label" to "Home folder", "subtitle" to "Your Linux files", "source" to "Files", "kind" to "folder", "id" to "home"),
            mapOf("label" to "Downloads", "subtitle" to "Downloaded files", "source" to "Files", "kind" to "folder", "id" to "Downloads"),
            mapOf("label" to "Documents", "subtitle" to "Documents folder", "source" to "Files", "kind" to "folder", "id" to "Documents"),
            mapOf("label" to "Pictures", "subtitle" to "Pictures folder", "source" to "Files", "kind" to "folder", "id" to "Pictures"),
            mapOf("label" to "Wi-Fi settings", "subtitle" to "Manage Android networks", "source" to "Settings", "kind" to "setting", "id" to "wifi"),
            mapOf("label" to "Bluetooth settings", "subtitle" to "Manage Android devices", "source" to "Settings", "kind" to "setting", "id" to "bluetooth"),
            mapOf("label" to "Display settings", "subtitle" to "Brightness and screen", "source" to "Settings", "kind" to "setting", "id" to "display"),
            mapOf("label" to "Sound settings", "subtitle" to "Volume and audio", "source" to "Settings", "kind" to "setting", "id" to "sound"),
            mapOf("label" to "Hotspot settings", "subtitle" to "Share mobile internet", "source" to "Settings", "kind" to "setting", "id" to "hotspot"),
        )
        results += shortcuts.filter { item ->
            needle.isEmpty() || item.values.any { it.lowercase().contains(needle) }
        }
        return results.distinctBy { "${it["kind"]}:${it["id"]}" }
            .sortedWith(compareBy<Map<String, String>> { it["label"]?.lowercase() }.thenBy { it["source"] })
            .take(limit)
    }

    fun createSnapshot(rooted: Boolean): Map<String, Any> {
        val stamp = SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(Date())
        val output = File(snapshotsDir, "DroidDesk-$stamp.zip")
        val home = linuxHome(rooted)
        ZipOutputStream(BufferedOutputStream(FileOutputStream(output))).use { zip ->
            zip.putNextEntry(ZipEntry("snapshot.properties"))
            zip.write("version=1\nmode=${if (rooted) "chroot" else "native"}\ncreated=${System.currentTimeMillis()}\n".toByteArray())
            zip.closeEntry()
            zip.putNextEntry(ZipEntry("packages.txt"))
            zip.write(installedPackages(rooted).joinToString("\n", postfix = "\n").toByteArray())
            zip.closeEntry()
            if (home.isDirectory) addDirectory(zip, home, "home")
        }
        return snapshotInfo(output)
    }

    fun listSnapshots(): List<Map<String, Any>> = snapshotsDir.listFiles { file -> file.extension == "zip" }
        ?.sortedByDescending(File::lastModified)
        ?.map(::snapshotInfo)
        .orEmpty()

    fun restoreSnapshot(name: String, rooted: Boolean): List<String> {
        val archive = safeSnapshot(name)
        val home = linuxHome(rooted)
        val rollback = File(home.parentFile, "${home.name}.before-restore")
        if (rollback.exists()) rollback.deleteRecursively()
        if (home.exists() && !home.renameTo(rollback)) error("Could not preserve the current Linux home")
        home.mkdirs()
        val packages = mutableListOf<String>()
        var snapshotMode: String? = null
        try {
            ZipInputStream(BufferedInputStream(FileInputStream(archive))).use { zip ->
                var entry = zip.nextEntry
                while (entry != null) {
                    when {
                        entry.name == "snapshot.properties" -> {
                            snapshotMode = zip.readBytes().toString(Charsets.UTF_8)
                                .lineSequence().firstOrNull { it.startsWith("mode=") }
                                ?.substringAfter('=')
                        }
                        entry.name == "packages.txt" -> {
                            packages += zip.readBytes().toString(Charsets.UTF_8)
                                .lineSequence().filter(::safePackageName)
                        }
                        entry.name.startsWith("home/") -> {
                            val relative = entry.name.removePrefix("home/")
                            if (relative.isNotEmpty()) {
                                val target = File(home, relative)
                                check(target.canonicalPath.startsWith(home.canonicalPath + File.separator))
                                if (entry.isDirectory) target.mkdirs() else {
                                    target.parentFile?.mkdirs()
                                    FileOutputStream(target).use { zip.copyTo(it) }
                                }
                            }
                        }
                    }
                    zip.closeEntry()
                    entry = zip.nextEntry
                }
            }
            val expectedMode = if (rooted) "chroot" else "native"
            require(snapshotMode == expectedMode) {
                "This snapshot belongs to a different Linux runtime mode"
            }
            rollback.deleteRecursively()
            return packages.distinct()
        } catch (error: Throwable) {
            home.deleteRecursively()
            rollback.renameTo(home)
            throw error
        }
    }

    fun deleteSnapshot(name: String): Boolean = safeSnapshot(name).delete()

    fun missingPackages(packages: List<String>, rooted: Boolean): List<String> {
        val installed = installedPackages(rooted).toSet()
        return packages.filter(::safePackageName).distinct().filterNot(installed::contains)
    }

    private fun linuxHome(rooted: Boolean): File = if (rooted) {
        File(context.filesDir, "rootfs/root")
    } else {
        File(context.filesDir, "home")
    }

    private fun installedPackages(rooted: Boolean): List<String> {
        val status = if (rooted) {
            File(context.filesDir, "rootfs/var/lib/dpkg/status")
        } else {
            listOf(
                File(context.filesDir, "usr/var/lib/dpkg/status"),
                File(context.filesDir, "dpkgroot/var/lib/dpkg/status"),
            ).firstOrNull(File::isFile) ?: return emptyList()
        }
        if (!status.isFile) return emptyList()
        return status.readText().split("\n\n").mapNotNull { block ->
            val fields = block.lineSequence().mapNotNull { line ->
                val split = line.indexOf(':')
                if (split <= 0) null else line.substring(0, split) to line.substring(split + 1).trim()
            }.toMap()
            fields["Package"]?.takeIf { fields["Status"] == "install ok installed" && safePackageName(it) }
        }.sorted()
    }

    private fun addDirectory(zip: ZipOutputStream, root: File, prefix: String) {
        root.walkTopDown().forEach { file ->
            if (file == root || file.isSymbolicLink()) return@forEach
            val relative = file.relativeTo(root).invariantSeparatorsPath
            val name = "$prefix/$relative${if (file.isDirectory) "/" else ""}"
            var entryOpen = false
            runCatching {
                zip.putNextEntry(ZipEntry(name).apply { time = file.lastModified() })
                entryOpen = true
                if (file.isFile) FileInputStream(file).use { it.copyTo(zip) }
            }.onFailure { Log.w(TAG, "Skipping snapshot entry $relative", it) }
                .also { if (entryOpen) runCatching { zip.closeEntry() } }
        }
    }

    private fun File.isSymbolicLink(): Boolean = runCatching {
        canonicalFile != absoluteFile
    }.getOrDefault(true)

    private fun desktopFields(file: File): Map<String, String> = runCatching {
        file.useLines { lines ->
            lines.takeWhile { !it.startsWith("[Desktop Action") }.mapNotNull { line ->
                val split = line.indexOf('=')
                if (split <= 0) null else line.substring(0, split) to line.substring(split + 1)
            }.toMap()
        }
    }.getOrDefault(emptyMap())

    private fun snapshotInfo(file: File): Map<String, Any> = mapOf(
        "name" to file.name,
        "sizeBytes" to file.length(),
        "created" to file.lastModified(),
    )

    private fun safeSnapshot(name: String): File {
        require(name.matches(Regex("DroidDesk-[0-9]{8}-[0-9]{6}\\.zip")))
        return File(snapshotsDir, name).also { require(it.isFile) }
    }

    private fun safePackageName(value: String): Boolean =
        value.matches(Regex("[a-z0-9][a-z0-9+.-]{0,127}"))
}
